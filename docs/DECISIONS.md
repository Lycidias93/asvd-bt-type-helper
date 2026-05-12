# Decisions

## v0.4.15 remains pre-release

The helper is verified on one Pixel setup and one target device. Public releases remain pre-release until more devices and OEM ROMs are tested.

## Targeting model

Public usage must support both unique device name and MAC address. MAC is preferred when there is any risk of duplicate names.

## SET guard

All metadata-changing commands require `--confirm-set`. GET and LIST are read-only.

## Magisk installer cleanup

The installer may remove only temporary `/data/app` installs of `org.asvd.bttypehelper`. It must not remove an existing `/system`, `/product`, `/system_ext`, or `/vendor` package path.

## Wrapper command paths

Helper scripts must use absolute `/system/bin/...` paths. Bare Android commands were proven unreliable in Termux/Magisk invocation contexts.

## AIO check rule

Maintainer checks should be bundled into one command with one output tail and explicit `RESULT:` markers whenever possible.
