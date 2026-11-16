#!/bin/bash
# After the run: which stop tests XCTest timed out (`timed_out.txt`, one stop id per line, read from the xcodebuild
# log) and their spindumps, copied out of the result bundle into `spindumps/`. The bundle's own test report and the
# attachment export are kept in the artifacts as evidence of what XCTest recorded.
set +e
A=ci/artifacts; R=$A/result.xcresult
mkdir -p $A/spindumps
sed -nE "s/.*Test Case '-\[[^ ]+ test_[0-9]+_([a-z0-9_]+)\]' exceeded execution time allowance.*/\1/p" $A/test.log 2>/dev/null \
  | tr '_' '-' | sort -u > $A/timed_out.txt
echo "TIMING timed out: $(tr '\n' ' ' < $A/timed_out.txt)"
if [ -d $R ]; then
  xcrun xcresulttool get test-results tests --path $R > $A/xcresult-tests.json 2> $A/xcresult-tests.err
  mkdir -p $A/xcresult-attachments $A/xcresult-diagnostics
  xcrun xcresulttool export attachments --path $R --output-path $A/xcresult-attachments > $A/xcresult-export.log 2>&1
  xcrun xcresulttool export diagnostics --path $R --output-path $A/xcresult-diagnostics >> $A/xcresult-export.log 2>&1
  python3 ci/spindumps.py $A/spindumps $A/timed_out.txt $A/xcresult-attachments $A/xcresult-diagnostics > $A/spindumps/index.log 2>&1
  # the first runs of a new harness keep the whole bundle (small: a few screenshots), so a parse that missed can be redone
  ditto -c -k --keepParent $R $A/result.xcresult.zip 2>/dev/null
  [ "$(stat -f %z $A/result.xcresult.zip 2>/dev/null || echo 0)" -gt 100000000 ] && rm -f $A/result.xcresult.zip
  rm -rf $R
fi
true
