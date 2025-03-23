# Additional Inputs

Add additional inputs for multiple things, see [ActionEvents](#action-events) for the exact list.

## Features

### Indicators / TurnSignal

Adds explicit inputs for indicating left / right and one for turning them off. Similar how an indicator lever in a car
works. Also adds the tip blink / comfort indicators functionality. If after the on signal an off signals follows within
500ms, the tip blink is activated.

Works great with the [Moza Stalks](https://mozaracing.com/product/multi-function-stalks/) for example.

### Lights

Adds new controls for normal front light on and off, also one for worklight front on.
The front light on action will also turn of the work light front. As this works best for me and the Moza Multi function
stalks. Translation from Moza Stalk lever turn thingi to FS25

* OFF -> Front lights OFF
* parking light -> Front lights ON
* Front light -> Worklight Front ON

I assigned the normal worklights back to the fog lights switch

### Implements

Add **Fold**, **Lower**, and **Activate** inputs for implements attached at the front or back. They are not bound to the
current selected part of the vehicle.

## Action Events

| Name                              | Key              | Description                                                                                                                                                                                                                      |
|-----------------------------------|------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| VD_AI_INDICATOR_LEFT_ON           |                  | Set the left turn signal to on, only works if Hazard lights are off                                                                                                                                                              |
| VD_AI_INDICATOR_RIGHT_ON          |                  | Set the right turn signal to on, only works if Hazard lights are off                                                                                                                                                             |
| VD_AI_INDICATOR_OFF               |                  | Turns off the turn signal, only works if Hazard lights are off. If pressed shortly after one of the two ON Actions, it assumes you wanted to use tip blink / comfort indicators. This will activate the indicators for 3 seconds |
| VD_AI_LOW_BEAM_OFF                |                  | Turns off the front lights / low beams                                                                                                                                                                                           |
| VD_AI_LOW_BEAM_ON                 |                  | Turn the front lights / low beams on, also turns off the front work light                                                                                                                                                        |
| VD_AI_FRONT_WORK_LIGHT_ON         |                  | Turn the front work lights on                                                                                                                                                                                                    |
| VD_AI_HIGH_BEAM_ON                |                  | Turn the high beams on                                                                                                                                                                                                           |
| VD_AI_HIGH_BEAM_OFF_FLASH_TRIGGER |                  | Turn the high beams off if they were on otherwise begin a flash, for moza you have to assign this button manually via inputbinding.xml to Button_6                                                                               |
| VD_AI_HIGH_BEAM_OFF_FLASH_RELEASE |                  | End the high beam flash - for moza you have to assign this button manually via inputbinding.xml to BUTTON_5                                                                                                                      |
| VD_AI_LOWER_FRONT                 | KEY_lshift KEY_v | Toggle lower state of all implements attached at the front                                                                                                                                                                       |
| VD_AI_LOWER_BACK                  | KEY_lalt KEY_v   | Toggle lower state of all implements attached at the back                                                                                                                                                                        |
| VD_AI_FOLD_FRONT                  | KEY_lshift KEY_x | Toggle folding state off all implements attached at the front                                                                                                                                                                    | 
| VD_AI_FOLD_BACK                   | KEY_lalt KEY_x   | Toggle folding state off all implements attached at the back                                                                                                                                                                     |
| VD_AI_ACTIVATE_FRONT              | KEY_lshift KEY_b | Toggle activation state all implements attached at the front                                                                                                                                                                     |
| VD_AI_ACTIVATE_BACK               | KEY_lalt KEY_b   | Toggle activation state all implements attached at the back                                                                                                                                                                      |~~

## Bindings for Moza Stalks

Replace ``<your_device_id>`` with the id of your moza stalk, best way to get this is to assign one of the buttons to it.
The replace these bindings in your ``inputBinding.xml``

````xml

<inputBinding>
    <!-- rest of the file -->

    <actionBinding action="VD_AI_INDICATOR_LEFT_ON">
        <binding device="<your_device_id>" input="BUTTON_10" axisComponent="+" neutralInput="0" index="1"/>
    </actionBinding>
    <actionBinding action="VD_AI_INDICATOR_RIGHT_ON">
        <binding device="<your_device_id>" input="BUTTON_8" axisComponent="+" neutralInput="0" index="1"/>
    </actionBinding>
    <actionBinding action="VD_AI_INDICATOR_OFF">
        <binding device="<your_device_id>" input="BUTTON_9" axisComponent="+" neutralInput="0" index="1"/>
    </actionBinding>
    <actionBinding action="VD_AI_FRONT_LIGHT_ON">
        <binding device="<your_device_id>" input="BUTTON_2" axisComponent="+" neutralInput="0" index="1"/>
    </actionBinding>
    <actionBinding action="VD_AI_FRONT_LIGHT_OFF">
        <binding device="<your_device_id>" input="BUTTON_1" axisComponent="+" neutralInput="0" index="1"/>
    </actionBinding>
    <actionBinding action="VD_AI_FRONT_WORK_LIGHT_ON">
        <binding device="<your_device_id>" input="BUTTON_3" axisComponent="+" neutralInput="0" index="1"/>
    </actionBinding>
    <actionBinding action="VD_AI_LOW_BEAM_ON">
        <binding device="<your_device_id>" input="BUTTON_2" axisComponent="+" neutralInput="0" index="1"/>
    </actionBinding>
    <actionBinding action="VD_AI_LOW_BEAM_OFF">
        <binding device="<your_device_id>" input="BUTTON_1" axisComponent="+" neutralInput="0" index="1"/>
    </actionBinding>
    <actionBinding action="VD_AI_HIGH_BEAM_ON">
        <binding device="<your_device_id>" input="BUTTON_4" axisComponent="+" neutralInput="0" index="1"/>
    </actionBinding>
    <actionBinding action="VD_AI_HIGH_BEAM_OFF_FLASH_TRIGGER">
        <binding device="<your_device_id>" input="BUTTON_6" axisComponent="+" neutralInput="0" index="1"/>
    </actionBinding>
    <actionBinding action="VD_AI_HIGH_BEAM_OFF_FLASH_RELEASE">
        <binding device="<your_device_id>" input="BUTTON_5" axisComponent="+" neutralInput="0" index="1"/>
    </actionBinding>
</inputBinding>
````