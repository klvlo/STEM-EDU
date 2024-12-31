local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 기존의 ScreenGui가 있다면 제거
local existingGui = playerGui:FindFirstChild("GuideGui")
if existingGui then
	existingGui:Destroy()
end

-- 새로운 ScreenGui 생성
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GuideGui"
screenGui.Parent = playerGui

-- 가이드 버튼 생성
local guideButton = Instance.new("TextButton")
guideButton.Size = UDim2.new(0, 160, 0, 45)  -- 버튼 크기 조정
guideButton.Position = UDim2.new(0, 1200, 0.5, -75)  -- "로비로 돌아가기" 버튼 위에 위치
guideButton.Text = "Guide"  -- 텍스트 변경
guideButton.Parent = screenGui

-- 버튼 스타일 설정
guideButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
guideButton.BorderSizePixel = 0
guideButton.Font = Enum.Font.GothamBold  -- 폰트 변경
guideButton.TextColor3 = Color3.new(1, 1, 1)
guideButton.TextSize = 16

-- 모서리 둥글게
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = guideButton

-- 그림자 효과
local shadow = Instance.new("Frame")
shadow.Size = UDim2.new(1, 4, 1, 4)
shadow.Position = UDim2.new(0, -2, 0, -2)
shadow.BackgroundColor3 = Color3.new(0, 0, 0)
shadow.BackgroundTransparency = 0.7
shadow.ZIndex = guideButton.ZIndex - 1
shadow.Parent = guideButton

local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(0, 8)
shadowCorner.Parent = shadow

-- 호버 효과
local function onMouseEnter()
	guideButton.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
end

local function onMouseLeave()
	guideButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
end

guideButton.MouseEnter:Connect(onMouseEnter)
guideButton.MouseLeave:Connect(onMouseLeave)

-- 가이드 화면 생성
local function createGuideScreen()
	local guideScreen = Instance.new("Frame")
	guideScreen.Size = UDim2.new(0.6, 0, 0.6, 0) -- 텍스트 박스 크기 조정
	guideScreen.Position = UDim2.new(0.2, 0, 0.2, 0)
	guideScreen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	guideScreen.Parent = screenGui

	local guideText = Instance.new("TextLabel")
	guideText.Size = UDim2.new(0.9, 0, 0.9, 0)
	guideText.Position = UDim2.new(0.05, 0, 0.05, 0)
	guideText.TextWrapped = true
	guideText.TextSize = 14
	guideText.TextXAlignment = Enum.TextXAlignment.Left -- 글씨 왼쪽 정렬
	guideText.Text = [[
명령어 사용법:

1. npc와 대화 : npc! [내용 입력]
2. 해당 유닛에 존재하는 문제 목록 가져오기 : quiz! [유닛 번호]
3. 해당 유닛에서 틀린 문제 목록 가져오기 : study! [유닛 번호]
4. 퀴즈 설명 받기 : more! [퀴즈 id]
5. 추가 퀴즈 설명 받기 : more! new
6. 추가 문제 제공 받기 : add! [퀴즈 번호] [난이도(상/중/하)]
]]
	guideText.Parent = guideScreen

	-- 닫기 버튼 생성
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 100, 0, 40)
	closeButton.Position = UDim2.new(0.5, -50, 1, -50)
	closeButton.Text = "Close"
	closeButton.Parent = guideScreen

	closeButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextSize = 16

	local UICornerClose = Instance.new("UICorner")
	UICornerClose.CornerRadius = UDim.new(0, 8)
	UICornerClose.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		guideScreen:Destroy()
	end)
end

guideButton.MouseButton1Click:Connect(createGuideScreen)
