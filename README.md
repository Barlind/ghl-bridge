# ghl-bridge

Guitar Hero Live Bluetooth Low Energy controller bridge command line tool for macOS. 

## Features

* Bridges a Guitar Hero Live BLE controller to macOS

## Quick Start

### Installation

#### [Mint](https://github.com/yonaskolb/mint)

```sh
mint install barlind/ghl-bridge
```

### Requirements

Since this application uses Bluetooth, you need to grant Bluetooth access to your favorite terminal emulator before
running `ghl-bridge`. Otherwise, the application will be halted by the OS. 

`ghl-bridge` needs access in Privacy & Security/Accessibility as it sends keystrokes to bridge the controller. 

### Usage

Looks for the Guitar Hero BLE peripheral called "Ble Guitar" and subscribes to updates, parses what buttons are being pressed and sends the keystrokes to macOS. Whammy and tilt values are NOT processed.

### Default Button Mapping

| Button      | Mapped Key  |
| ----------- | ----------- |
| Black 1     | 1           |
| Black 2     | 2           |
| Black 3     | 3           |
| White 1     | 4           |
| White 2     | 5           |
| White 3     | 6           |
| Strum Up    | A           |
| Strum Down  | B           |
| Pause       | Return      |
| Star Power  | S           |
| GHTV        | .           |

## Motivation

I got a hankering for playing some Guitar Hero and remembered that I had an old Guitar Hero Live controller that I never used since the service was discontinued. A quick google turned up [GHLiveBLE](https://jsyang.ca/hacks/ghliveble/) - but there was a problem. Whenever I tried using it with Clone Hero on my Macbook Pro M1 it would start lagging. The culprit turned out to be the tilt sensor, sending constant updates which I really didn't need.

Thus ghl-bridge ignores the whammy and tilt updates and only passes on the buttons I actually wanted to use. Lag gone - rock on!

## Plans (?)

- [ ] Debug output
- [ ] Support for multiple guitars
- [ ] Keypress disabling
- [ ] TUI 

## Contribution

Please use under the terms of the MIT license. As always, I welcome any form of contribution.

## Acknowledgements

Being my first macOS CLI tool AND first BLE project I learned a lot from these projects:

- [core-bluetooth-tool](https://github.com/mickeyl/core-bluetooth-tool)
- [ghlioscon](https://github.com/tomyun/ghlioscon)

Thank you for open sourcing!