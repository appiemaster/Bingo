
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/UI }
using { /Verse.org/Colors }
using { /Verse.org/Colors/NamedColors }
using { /Verse.org/Random }
# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
bingo_handler := class():

    AmountOfCols : int = 5
    AmountOfRows : int = 5
    var PlayerUIInfo : ?ui_info = false
    var AllNumbers : []int = array{}
    var MinNumber : int = 1
    var MaxNumber  : int = 80
    var AllButtons : []button_regular = array{}
    var SelectedButtons : []button_regular = array{}
    var MinAndMax : []int = array{0, 13, 26, 39, 52, 65, 79}
    var RANDOMtuplE : tuple(int, int) = (22, 2)
    BingoEvent : event(agent) 
    XMsg<localizes>:message = "❌"
    CheckMsg<localizes>:message = "✅"

    CloseButton : button_loud = button_loud{}

    Init():void=
        CloseButton.SetText(XMsg)

    I2M<localizes> (I : int) : message = "{I}"

    OnNumberClicked(WM : widget_message):void=
        if(Index := AllButtons.Find[WM.Source], ButtonThatWasClicked := AllButtons[Index], not SelectedButtons.Find[ButtonThatWasClicked]):
            ButtonThatWasClicked.SetText(CheckMsg)
            set SelectedButtons += array{ButtonThatWasClicked}
            CheckForBingo(WM.Player)
    CheckForButton(NumberDrawn : int):void=
        Print("Number that was drawn: {NumberDrawn}")
        for(NumberButton : AllButtons):
            NumberOfTheBtn := NumberButton.GetText()
            if("{NumberDrawn}" = NumberOfTheBtn):
                NumberButton.SetEnabled(true)


    
    CheckForBingo(Agent : agent):void=
        if(SelectedButtons.Length = 25):
            Print("Bingo!")
            BingoEvent.Signal(Agent)
    AssingBingoUI(Agent : agent):void=
        if(PlayerUI := GetPlayerUI[player[Agent]], PlayerBingoCanvas := PlayerUIInfo?.Canvas) then PlayerUI.AddWidget(PlayerBingoCanvas, player_ui_slot{InputMode := ui_input_mode.All})

    RemoveBingoUI(WM : widget_message):void=
        if(PlayerUI := GetPlayerUI[WM.Player], PlayerCanvas := PlayerUIInfo?.Canvas):
            PlayerUI.RemoveWidget(PlayerCanvas)

    ManuallyRemoveBingoUI(Agent : agent):void=
        if(PlayerUI := GetPlayerUI[player[Agent]], PlayerCanvas := PlayerUIInfo?.Canvas):
            PlayerUI.RemoveWidget(PlayerCanvas)

    HideBingoUI(WM : widget_message):void=
        if(PlayerUI := GetPlayerUI[WM.Player], PlayerCanvas := PlayerUIInfo?.Canvas):
            PlayerCanvas.SetVisibility(widget_visibility.Collapsed)
    

    EmptyBingoData():void=
        set AllNumbers = array{}
        set AllButtons = array{}
        set SelectedButtons = array{}
    GenerateNumberButtons():[]stack_box=
        var AllColumns : []stack_box = array{}
        for(I := 1..AmountOfCols):
            Print("Creating the column")
            SingularCol : stack_box = stack_box{Orientation := orientation.Vertical}
            var CurrentButtons : []button_regular = array{}
            for(Y := 1..AmountOfRows):
                loop:
                    if(MinimumVal := MinAndMax[I - 1], MaximumVal := MinAndMax[I]):
                        RandomGeneratedNumber := GetRandomInt(MinimumVal, MaximumVal)
                        if(RandomNumber := AllNumbers[RandomGeneratedNumber], TempArray := AllNumbers.RemoveElement[RandomGeneratedNumber]):
                            set AllNumbers = TempArray
                            NumberButton := button_regular{}
                            if(I = 3 and Y = 3):
                                NumberButton.SetEnabled(true)
                                NumberButton.SetText(XMsg)
                            else:
                                NumberButton.SetEnabled(false)
                                NumberButton.SetText(I2M(RandomNumber))
                            NumberButton.OnClick().Subscribe(OnNumberClicked)
                            set CurrentButtons += array{NumberButton}
                            set AllButtons += array{NumberButton}
                            Print("Creating the numbers, {RandomNumber}")
                            break
                    

            for(NumberButton : CurrentButtons):
                Print("Adding the numbers")
                MyStackBoxSlot := stack_box_slot: 
                    Widget := NumberButton 
                    Padding := margin{Top := 5.0,Right := 5.0, Left := 5.0, Bottom := 5.0}
                SingularCol.AddWidget(MyStackBoxSlot)
            set AllColumns += array{SingularCol}
        return AllColumns

    
    MakeBingoCanvas():canvas=
        UIInfo := ui_info{}
        set AllNumbers = array{}
        for(I := MinNumber..MaxNumber):
            set AllNumbers += array{I}
        CloseButton.OnClick().Subscribe(RemoveBingoUI)

        WrapperStackbox := stack_box:
            Orientation := orientation.Horizontal
        AllNumberButtons := GenerateNumberButtons()
        for(SingularCol : AllNumberButtons):
            MyStackBoxSlot := stack_box_slot  . Widget := SingularCol
            WrapperStackbox.AddWidget(MyStackBoxSlot)
            Print("Loopin")
        MyColor := MakeColorFromHex("FF4C00FF")
        BgColor:= MakeColorFromHex("4257FFFF")
        MainOverlay := overlay:
            Slots := array:
                overlay_slot:
                    Widget := texture_block:
                        DefaultImage := img.white_bg
                        DefaultDesiredSize := vector2{X:= 748.51062, Y := 597.155945}
                        DefaultTint := BgColor
                overlay_slot:
                    Widget := texture_block:
                        DefaultImage := img.BINGO_
                        DefaultDesiredSize := vector2{X:= 337.674286, Y := 76.575157}
                        DefaultTint := MyColor
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Top := 35.0}
                overlay_slot:
                    Widget := WrapperStackbox
                    HorizontalAlignment := horizontal_alignment.Center
                    VerticalAlignment := vertical_alignment.Bottom
                    Padding := margin{Bottom := 35.0}
                overlay_slot:
                    Widget := CloseButton
                    HorizontalAlignment := horizontal_alignment.Right
                    VerticalAlignment := vertical_alignment.Top
                    Padding := margin{Right := 10.0, Top := 10.0}
        MainCanvas := canvas:
            Slots := array:
                canvas_slot:
                    Widget := MainOverlay
                    Anchors := anchors:
                        Minimum := vector2{X := 0.5, Y:= 0.5},
                        Maximum := vector2{X := 0.5, Y:= 0.5}
                    Alignment := vector2{X := 0.5, Y:= 0.3}
        set UIInfo.Canvas = MainCanvas
        set PlayerUIInfo = option{UIInfo}
        return MainCanvas
