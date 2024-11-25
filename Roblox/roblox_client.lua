local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:FindFirstChild("ScreenGui")

if screenGui then
	screenGui.Enabled = true
	print("ScreenGui 활성화 성공")
else
	warn("ScreenGui를 찾을 수 없습니다.")
end

local textBox = screenGui.Frame:WaitForChild("NPCBox")
local nextButton = screenGui.Frame:WaitForChild("NPCButton")
local answerInput = screenGui.Frame:WaitForChild("AnswerBox")
local submitButton = screenGui.Frame:WaitForChild("SubmitButton")

local MoreResponseRemote = ReplicatedStorage:WaitForChild("MoreResponseRemote")
local CheckAnswerRemote = ReplicatedStorage:WaitForChild("CheckAnswerRemote")

local currentPage = 1
local messages = {}

-- 페이지 나누기 함수 (TextFits로 크기에 맞추기)
local function splitMessageIntoPages(fullMessage)
	messages = {}
	local tempText = ""

	-- 단어 단위로 메시지를 나눔
	for word in fullMessage:gmatch("%S+") do
		tempText = tempText .. word .. " "
		textBox.Text = tempText

		-- 텍스트가 박스를 벗어나면 한 페이지로 추가
		if not textBox.TextFits then
			table.insert(messages, tempText:sub(1, #tempText - #word - 1))
			tempText = word .. " " -- 다음 페이지에 현재 단어 추가
		end
	end

	-- 마지막 페이지 추가
	if tempText ~= "" then
		table.insert(messages, tempText)
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
		currentPage = 1  -- 처음으로 돌아가기
	end
	updatePage()
end)

MoreResponseRemote.OnClientEvent:Connect(function(responseMessage)
	print("클라이언트에서 수신된 메시지:", responseMessage)

	splitMessageIntoPages(responseMessage)
	currentPage = 1
	updatePage()
	screenGui.Enabled = true
	print("GUI가 화면에 표시되었습니다.")
end)

-- 정답 확인 요청
submitButton.MouseButton1Click:Connect(function()
	print("정답 가져오기 요청")
	CheckAnswerRemote:FireServer()
end)

-- 서버로부터 정답 메시지 수신
CheckAnswerRemote.OnClientEvent:Connect(function(resultMessage, correctAnswer)
	-- 정답 처리
	if correctAnswer then
		textBox.Text = correctAnswer
	else
		textBox.Text = "퀴즈 정보를 가져올 수 없습니다."
	end

	-- 메시지 처리
	if resultMessage then
		textBox.Text = resultMessage
	end
end)
