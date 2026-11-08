#!/usr/bin/env python3
"""Run real mobile Patrol UI tests; retain runner evidence outside Manual."""
import argparse
import json
from datetime import datetime
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
MOBILE = set(range(1, 28)) - {13, 14, 16, 23, 27}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--platform', choices=('ios', 'android'), default='ios')
    parser.add_argument('--device', required=True, help='Device id from `patrol devices`')
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument('--suite', help='For example STC-02; omit for all 22 suites')
    selection.add_argument('--ready', action='store_true',
                           help='Run the four login/logout/profile cases in one build')
    args = parser.parse_args()
    if args.suite and args.suite not in {f'STC-{n:02}' for n in MOBILE}:
        parser.error('Choose one of the 22 mobile STC suites')
    if not (ROOT / '.env.ui.local.json').is_file():
        parser.error('Copy .env.ui.example.json to .env.ui.local.json and fill the test fixtures')
    patrol = shutil.which('patrol')
    if not patrol:
        parser.error('patrol_cli 4.8.0 is required; install it with dart pub global activate patrol_cli 4.8.0')
    result = ROOT / 'patrol-results' / datetime.now().strftime('%Y%m%d-%H%M%S')
    result.mkdir(parents=True)
    command = [patrol, 'test', '--device', args.device,
               '--dart-define-from-file=.env.ui.local.json']
    if args.suite:
        command += ['--tags', args.suite]
    if args.ready:
        command += ['--target', 'tool/ui_batches/ready_test.dart']
    config = json.loads((ROOT / '.env.ui.local.json').read_text())
    secrets = sorted({v for k, v in config.items()
                      if any(s in k for s in ('PASSWORD', 'EMAIL')) and v},
                     key=len, reverse=True)
    android_results = ROOT / 'build/app/outputs/androidTest-results'
    previous_xml = (
        {p: p.stat().st_mtime_ns for p in android_results.rglob('*.xml')}
        if android_results.exists() else {}
    )
    previous_xcresults = {
        p: p.stat().st_mtime_ns for p in (ROOT / 'build').glob('ios_results_*.xcresult')
    }
    with (result / 'runner.log').open('w') as log:
        process = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, text=True)
        for line in process.stdout:
            for secret in secrets:
                line = line.replace(secret, '[redacted]')
            print(line, end='')
            log.write(line)
        code = process.wait()
    # Copy only artifacts created/changed by this invocation. Never infer
    # product PASS/FAIL from a runner exit code or fabricate a summary.
    if args.platform == 'android' and android_results.exists():
        for xml in android_results.rglob('*.xml'):
            if previous_xml.get(xml) == xml.stat().st_mtime_ns:
                continue
            dest = result / 'junit' / xml.relative_to(android_results)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(xml, dest)
    if args.platform == 'ios':
        for bundle in (ROOT / 'build').glob('ios_results_*.xcresult'):
            if previous_xcresults.get(bundle) == bundle.stat().st_mtime_ns:
                continue
            shutil.copytree(bundle, result / bundle.name, dirs_exist_ok=True)
    print(f'Automated evidence: {result.relative_to(ROOT)} (exit {code})')
    return code


if __name__ == '__main__':
    sys.exit(main())
