local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "Cherry Hub", HidePremium = false,IntroText = "Cherry Hub" ,SaveConfig = true, ConfigFolder = "OrionTest"})
 
 OrionLib:MakeNotification({
    Name = "FreeFire!",
    Content = "Dont play freefire!",
    Image = "rbxassetid://4483345998",
    Time = 5
})
 
  local MainTab = Window:MakeTab({
    Name = "Cherry Hub",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

  local Section = MainTab:AddSection({
    Name = "Cherry Hub Section"
})
  
  
  MainTab:AddButton({
    Name = "Button!",
    Callback = function()
              print("FreeFire?")
      end    
})

 MainTab:AddToggle({
    Name = "FreeHub",
    Default = false,
    Callback = function(Value)
        print("ByHungdz")
    end    
})
  
 MainTab:AddColorpicker({
    Name = "Colorpicker",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Value)
        print(Value)
    end      
})
 
 MainTab:AddSlider({
    Name = "Slider",
    Min = 0,
    Max = 20,
    Default = 5,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "bananas",
    Callback = function(Value)
        print(Value)
    end    
})
UI thoi nhin lam gi=))
