# Additional Inputs

Add additional inputs for multiple things, see [ActionEvents](#action-events) for the exact list.

## Features

### Indicators / TurnSignal

Adds explicit inputs for indicating left / right and one for turning them off. Similar how an indicator lever in a car
works. Also adds the tip blink / comfort indicators functionality. If after the on signal an off signals follows within
500ms, the tip blink is activated.

Works great with the [Moza Stalks](https://mozaracing.com/product/multi-function-stalks/) for example.

### Implements

Add **Fold**, **Lower**, and **Activate** inputs for implements attached at the front or back. They are not bound to the
current selected part of the vehicle.

## Action Events

| Name                     | Key              | Description                                                                                                                                                                                                                     |
|--------------------------|------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| VD_AI_INDICATOR_LEFT_ON  |                  | Set the left turn signal to on, only works if Hazard lights are off                                                                                                                                                             |
| VD_AI_INDICATOR_RIGHT_ON |                  | Set the right turn signal to on, only works if Hazard lights are off                                                                                                                                                            |
| VD_AI_INDICATOR_OFF      |                  | Turns of the turn signal, only works if Hazard lights are off. If pressed shortly after one of the two ON Actions, it assumes you wanted to use tip blink / comfort indicators. This will activate the indicators for 3 seconds |
| VD_AI_LOWER_FRONT        | KEY_lshift KEY_v | Toggle lower state of all implements attached at the front                                                                                                                                                                      |
| VD_AI_LOWER_BACK         | KEY_lalt KEY_v   | Toggle lower state of all implements attached at the back                                                                                                                                                                       |
| VD_AI_FOLD_FRONT         | KEY_lshift KEY_x | Toggle folding state off all implements attached at the front                                                                                                                                                                   | 
| VD_AI_FOLD_BACK          | KEY_lalt KEY_x   | Toggle folding state off all implements attached at the back                                                                                                                                                                    |
| VD_AI_ACTIVATE_FRONT     | KEY_lshift KEY_b | Toggle activation state all implements attached at the front                                                                                                                                                                    |
| VD_AI_ACTIVATE_BACK      | KEY_lalt KEY_b   | Toggle activation state all implements attached at the back                                                                                                                                                                     |
