local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScreenGui"
screenGui.Parent = playerGui
screenGui.Enabled = false -- Initially hide the ScreenGui

-- Create Frame
local frame = Instance.new("Frame")
frame.Name = "Frame"
frame.Size = UDim2.new(0.5, 0, 0.3, 0) -- Adjust the size of the frame
frame.Position = UDim2.new(0.25, 0, 0, 0) -- Move the frame to the top
frame.BackgroundTransparency = 0.5 -- Set the transparency to 50%
frame.Parent = screenGui

-- Create TextBox for response
local textBox = Instance.new("TextBox")
textBox.Name = "NPCBox"
textBox.Size = UDim2.new(0.9, 0, 0.4, 0) -- Adjust the size of the text box
textBox.Position = UDim2.new(0.05, 0, 0.1, 0) -- Center the text box within the frame
textBox.TextWrapped = true
textBox.TextSize = 10 -- Reduce the font size
textBox.Parent = frame

-- Create Answer Input
local answerInput = Instance.new("TextBox")
answerInput.Name = "AnswerBox"
answerInput.Size = UDim2.new(0.9, 0, 0.2, 0) -- Adjust the size of the answer input
answerInput.Position = UDim2.new(0.05, 0, 0.55, 0) -- Position below the text box
answerInput.PlaceholderText = "Enter your answer"
answerInput.Parent = frame

-- Create Submit Button
local submitButton = Instance.new("TextButton")
submitButton.Name = "SubmitButton"
submitButton.Size = UDim2.new(0.4, 0, 0.2, 0) -- Adjust the size of the submit button
submitButton.Position = UDim2.new(0.05, 0, 0.8, 0) -- Position below the answer input
submitButton.Text = "Submit"
submitButton.Parent = frame

-- Create Next Button
local nextButton = Instance.new("TextButton")
nextButton.Name = "NPCButton"
nextButton.Size = UDim2.new(0.4, 0, 0.2, 0) -- Adjust the size of the next button
nextButton.Position = UDim2.new(0.55, 0, 0.8, 0) -- Position next to the submit button
nextButton.Text = "Next"
nextButton.Parent = frame

-- Create Close Chat Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 160, 0, 45) -- Adjust the size of the close button
closeButton.Position = UDim2.new(0, 1200, 0.5, 25) -- Position above the "로비로 돌아가기" button
closeButton.Text = "Close Chat"
closeButton.Parent = screenGui

-- 버튼 스타일 설정
closeButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold  -- 폰트 변경
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 16

-- 모서리 둥글게
local UICornerClose = Instance.new("UICorner")
UICornerClose.CornerRadius = UDim.new(0, 8)
UICornerClose.Parent = closeButton

-- 그림자 효과
local shadowClose = Instance.new("Frame")
shadowClose.Size = UDim2.new(1, 4, 1, 4)
shadowClose.Position = UDim2.new(0, -2, 0, -2)
shadowClose.BackgroundColor3 = Color3.new(0, 0, 0)
shadowClose.BackgroundTransparency = 0.7
shadowClose.ZIndex = closeButton.ZIndex - 1
shadowClose.Parent = closeButton

local shadowCornerClose = Instance.new("UICorner")
shadowCornerClose.CornerRadius = UDim.new(0, 8)
shadowCornerClose.Parent = shadowClose

-- 호버 효과
local function onMouseEnterClose()
	closeButton.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
end

local function onMouseLeaveClose()
	closeButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
end

closeButton.MouseEnter:Connect(onMouseEnterClose)
closeButton.MouseLeave:Connect(onMouseLeaveClose)

local MoreResponseRemote = ReplicatedStorage:WaitForChild("MoreResponseRemote")
local CheckAnswerRemote = ReplicatedStorage:WaitForChild("CheckAnswerRemote")

local currentPage = 1
local messages = {}

-- 페이지 나누기 함수 (줄바꿈 기준으로 나누기)
local function splitMessageIntoPages(fullMessage)
	messages = {}
	for line in fullMessage:gmatch("[^\r\n]+") do
		table.insert(messages, line)
	end
end

local function updatePage()
	if messages[currentPage] then
		textBox.Text = messages[currentPage]
		print("현재 페이지 내용:", messages[currentPage])
	else
		textBox.Text = "더 이상 내용이 없습니다."
		print("마지막 페이지에 도달했습니다.")
	end
end

nextButton.MouseButton1Click:Connect(function()
	currentPage = currentPage + 1
	if currentPage > #messages then
		currentPage = 1
	end
	updatePage()
end)

MoreResponseRemote.OnClientEvent:Connect(function(responseMessage)
	print("클라이언트에서 수신된 메시지:", responseMessage)

	splitMessageIntoPages(responseMessage)
	currentPage = 1
	updatePage()
	screenGui.Enabled = true -- Show the ScreenGui when a response is received
	print("GUI가 화면에 표시되었습니다.")
end)

submitButton.MouseButton1Click:Connect(function()
	if answerInput.Text ~= "" then
		print("정답 가져오기 요청")
		CheckAnswerRemote:FireServer(answerInput.Text)
		answerInput.Text = "" -- Clear the text box after submission
	else
		print("입력창이 비어 있습니다.")
	end
end)

CheckAnswerRemote.OnClientEvent:Connect(function(resultMessage, correctAnswer)
	if correctAnswer then
		textBox.Text = correctAnswer
	else
		textBox.Text = "퀴즈 정보를 가져올 수 없습니다."
	end

	if resultMessage then
		textBox.Text = resultMessage
	end
end)

-- Close button functionality
closeButton.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)
