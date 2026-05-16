# ASVD BT Type Helper v0.6.1

## Scope

FD-detach and GET-result hardening release.

## Root cause

On the verified Pixel/Termux/Magisk path, direct `am broadcast` from a root shell attached to the Termux PTY can fail before `BtTypeReceiver` is invoked:

```text
cmd: Failure calling service activity: Failed transaction
avc: denied { read write } for path="/dev/pts/0"
scontext=u:r:system_server:s0
tcontext=u:object_r:untrusted_app_all_devpts:s0
```

A detached FD probe showed that the receiver works when framework command file descriptors are not backed by the Termux PTY.

## Changes

- Run `am broadcast` detached from the Termux PTY.
- Capture package preflight output before printing in helper wrappers that source `helper-common.sh`.
- Add strict GET result validation with `request_id` polling.
- Make `helper-get.sh` fail if no fresh GET result file exists.
- Make `helper-doctor.sh` fail on GET smoke failure instead of warning only.

## Safety

- LIST/GET/Doctor flows remain read-only.
- No metadata write behavior was changed.
- Confirmed SET/CLEAR commands remain guarded.

## Verify markers

```text
PASS list_result_valid
PASS get_result_valid
RESULT: ASVD_BT_TYPE_HELPER_LIST_WRAPPER_DONE
RESULT: ASVD_BT_TYPE_HELPER_GET_WRAPPER_DONE
RESULT: ASVD_BT_TYPE_HELPER_DOCTOR_PASS
```
