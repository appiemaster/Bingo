
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/UI }
using { /Verse.org/Colors }
using { /Verse.org/Colors/NamedColors }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Characters }
using { /Verse.org/Random }
# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
game_manager := class(creative_device):

    @editable 
    Spawners : []player_spawner_device = array{}

    var BingoMap : [agent]bingo_handler = map{}

    @editable
    BingoButton : button_device = button_device{}
    var MinNumber : int = 1
    var MaxNumber  : int = 80
    var AllNumbers : []int = array{}
    var SelecetedNumbers : []int = array{}

    


    @editable
    SelectedNumbersBoard : billboard_device = billboard_device{}
    
    @editable
    UnselectedNumbersBoard : billboard_device = billboard_device{}

    @editable
    WinnerStatusBoard : billboard_device = billboard_device{}

    @editable
    CoolDownBoard : billboard_device = billboard_device{}

    @editable
    NumberDrawnBoard : billboard_device = billboard_device{}

    @editable
    PlayerReferenceDevice : player_reference_device = player_reference_device{}

    UnselectedMsg<localizes>:message = "Unselected numbers :"
    SelectedMsg<localizes>:message = "Selected numbers :"
    NumberDrawnMsg<localizes>:message = "Number drawn:"
    CooldownMsg<localizes>:message = "Time till next draw:"
    WinMsg<localizes>:message = "has won!"
    DefaultWinStatusMsg<localizes>:message = "No winner yet..."
    WaitingForGameStartMsg<localizes>:message = "Waiting for game to start..."
    NextRoundMsg<localizes>:message = "Next round in :"

    BingoEvent : event(agent) = event(agent){}
    var MaxTime : int = 0
    var Timer : int = 4 
    var GameOn : logic = true
    OnBegin<override>()<suspends>:void=
        Print("game started")
        for(Spawner : Spawners):
            spawn{Spawner.AwaitPlayerSpawn()}
        MakeNewNumbers()
        spawn{AwaitPlayerLeft()}
        spawn{AwaitButtonPress()}
        spawn{AwaitBingoWin()}
        Sleep(5.0)
        WinnerStatusBoard.SetText(DefaultWinStatusMsg)
        spawn{GameHandler()}
        spawn{UpdateTimerBingoDiplay()}

    GameHandler()<suspends>:void=
        loop:
            if(GameOn?):
                Print("Drawing number!")
                NumberDrawn := GetRandomNumer()
                for(CurrentAgent -> BingoObj : BingoMap):
                    BingoObj.CheckForButton(NumberDrawn)
                    Print("Checking!")
                NumberDrawnBoard.SetText(ConcatenateMessages(NumberDrawnMsg, I2M(NumberDrawn)))
                UpdatingUnselectedNumbersDisplay()
                UpdatingSelectedNumbersDisplay()
                Sleep(3.0)
            else:
                break

    AwaitBingoWin()<suspends>:void=
        loop:
            Agent := BingoEvent.Await()
            Print("A player has bingo!")
            OnBingoWin(Agent)
            Sleep(5.0)
            spawn{ResetGame()}

    ResetGame()<suspends>:void=
        MakeNewNumbers()
        set Timer = 30
        UnselectedNumbersBoard.SetText(WaitingForGameStartMsg)
        SelectedNumbersBoard.SetText(WaitingForGameStartMsg)
        NumberDrawnBoard.SetText(WaitingForGameStartMsg)
        for(CurrentAgent -> BingoObj : BingoMap):
            BingoObj.EmptyBingoData()
            BingoObj.ManuallyRemoveBingoUI(CurrentAgent)
            BingoObj.MakeBingoCanvas()
        Sleep(30.0)
        Print("Done.")
        set Timer = 4
        set GameOn = true
        spawn{GameHandler()}
        PlayerReferenceDevice.Clear()
        NumberDrawnBoard.SetText(WaitingForGameStartMsg)
        WinnerStatusBoard.SetText(DefaultWinStatusMsg)
    OnBingoWin(Agent : agent):void=
        AgentMsg := A2M(Agent)
        WinnerStatusBoard.SetText(ConcatenateMessages(AgentMsg, WinMsg))
        set Timer = 6
        set GameOn = false
        PlayerReferenceDevice.Register(Agent)
    UpdatingUnselectedNumbersDisplay():void=
        var Unselectednumbers : string = ""
        for(Index -> Number : AllNumbers):
            if(not Index = 0):
                set Unselectednumbers += ", {Number}"
            else:
                set Unselectednumbers += "{Number}"
        UnselectedNumbersBoard.SetText(ConcatenateMessages(UnselectedMsg, S2M(Unselectednumbers)))

    UpdatingSelectedNumbersDisplay():void=
        var SelectedNumbers : string = ""
        for(Index -> Number : SelecetedNumbers):
            if(not Index = 0):
                set SelectedNumbers += ", {Number}"
            else:
                set SelectedNumbers += "{Number}"
            
        SelectedNumbersBoard.SetText(ConcatenateMessages(SelectedMsg, S2M(SelectedNumbers)))

    UpdateTimerBingoDiplay()<suspends>:void=
        loop:
            Sleep(1.0)
            if(Timer = 1):
                set Timer = 4
            set Timer -= 1
            if(GameOn?):
                CoolDownBoard.SetText(ConcatenateMessages(CooldownMsg, I2M(Timer)))
            else:
                CoolDownBoard.SetText(ConcatenateMessages(NextRoundMsg, I2M(Timer)))

    (Spawner : player_spawner_device).AwaitPlayerSpawn()<suspends>:void=
        loop:
            Agent := Spawner.SpawnedEvent.Await()
            InitAgents(Agent)
    GetRandomNumer():int=
        loop:
            RandomGeneratedNumber := GetRandomInt(0, AllNumbers.Length - 1)
            if(RandomNumber := AllNumbers[RandomGeneratedNumber], TempArray := AllNumbers.RemoveElement[RandomGeneratedNumber]):
                set SelecetedNumbers += array{RandomNumber}
                set AllNumbers = TempArray
                return RandomNumber
            else if(not AllNumbers[0]):
                Print("No Numbers left.")
                MakeNewNumbers()
                spawn{ResetGame()}
            else:
                Print("Len {AllNumbers.Length}")
    MakeNewNumbers():void=
        set AllNumbers = array{}
        set SelecetedNumbers = array{}
        for(I := MinNumber..MaxNumber):
            set AllNumbers += array{I}
    ConcatenateMessages<localizes>(Msg1 : message, Msg2 : message): message = "{Msg1} {Msg2}"
    S2M<localizes>(S : string):message = "{S}"
    I2M<localizes>(I: int):message = "{I}"
    A2M<localizes>(A: agent):message = "{A}"
    AwaitButtonPress()<suspends>:void=
        loop:
            Agent := BingoButton.InteractedWithEvent.Await()
            if(BingoPlayer := BingoMap[Agent]):
                BingoPlayer.AssingBingoUI(Agent)
                
    InitAgents(Agent : agent):void=
        if(not BingoMap[Agent]):
            PlayerObj := bingo_handler{BingoEvent := BingoEvent, MaxNumber := MaxNumber}
            PlayerObj.Init()
            PlayerObj.MakeBingoCanvas()
            if(set BingoMap[Agent] = PlayerObj){} 
            Print("set")
    
    AwaitPlayerLeft()<suspends>:void=
        loop:
            Player := GetPlayspace().PlayerRemovedEvent().Await()
            OnPlayerRemoved(Player)

    OnPlayerRemoved(Player : player): void=
        if(RemoveCustomPlayer:= BingoMap[Player]):
                var TempAllPlayersMap: [agent] bingo_handler = map{}
                for (Key -> Value: BingoMap, Key <> Player):
                    set  TempAllPlayersMap = ConcatenateMaps(TempAllPlayersMap, map{Key => Value})
                set BingoMap = TempAllPlayersMap
