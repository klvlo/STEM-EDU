local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ChatService = game:GetService("Chat")
local teacher = game.Workspace:FindFirstChild("Teacher")

-- 서버 URL 설정
local mainApiUrl = "http://localhost:3000"
local gptApiUrl = "http://localhost:3000/chat"
local scoreApiUrl = "http://localhost:3000/save-score"
local attemptApiUrl = "http://localhost:3000/save-attempt"

-- BindableEvent 설정
local function getOrCreateBindableEvent(eventName)
	local event = ReplicatedStorage:FindFirstChild(eventName)
	if not event then
		event = Instance.new("BindableEvent")
		event.Name = eventName
		event.Parent = ReplicatedStorage
	end
	return event
end

-- RemoteEvent 설정
local function getOrCreateRemoteEvent(eventName)
	local event = ReplicatedStorage:FindFirstChild(eventName)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = eventName
		event.Parent = ReplicatedStorage
	end
	return event
end

-- BindableEvent들 설정
local ScoreEventBindable = getOrCreateBindableEvent("ScoreEventBindable")
local AttemptEventBindable = getOrCreateBindableEvent("AttemptEventBindable")

-- RemoteEvent 생성
local MoreResponseRemote = getOrCreateRemoteEvent("MoreResponseRemote")
local CheckAnswerRemote = getOrCreateRemoteEvent("CheckAnswerRemote")

-- 서버로 요청 보내는 공통 함수
local function sendRequest(url, data)
	local jsonData = HttpService:JSONEncode(data)
	local success, response = pcall(function()
		return HttpService:PostAsync(url, jsonData, Enum.HttpContentType.ApplicationJson)
	end)
	return success, response
end

-- 점수 전송
local function sendScore(userId, score)
	local data = { user_id = userId, score = score }
	local success, response = sendRequest(scoreApiUrl, data)
	if success then
		print("점수 전송 성공:", response)
	else
		warn("점수 전송 오류:", response)
	end
end

-- 퀴즈 시도 결과 전송
local function sendQuizAttempt(userId, quizId, isCorrect)
	local data = { user_id = userId, quiz_id = quizId, is_correct = isCorrect }
	local success, response = sendRequest(attemptApiUrl, data)
	if success then
		print("퀴즈 시도 결과 전송 성공:", response)
	else
		warn("퀴즈 시도 결과 전송 오류:", response)
	end
end

-- NPC와의 채팅 처리
local teacher = workspace:FindFirstChild("Teacher")

local function sendChatMessage(message)
	if teacher and teacher:FindFirstChild("Head") then
		ChatService:Chat(teacher.Head, message, Enum.ChatColor.Blue)
	end
end

local function handleNpcCommand(player, args)
	-- 질문 내용은 명령 인수에서 두 번째 인수로 받음
	local userMessage = args  -- 첫 번째 인수는 'npc!'이므로 두 번째 인수부터 시작

	-- 질문이 존재하는지 확인
	if userMessage and userMessage ~= "" then
		local data = {
			message = userMessage  -- 사용자 질문을 서버로 보냄
		}

		-- 서버에 요청 보내기
		local success, response = sendRequest(mainApiUrl .. "/chat", data)

		if success then
			local decodedResponse = game:GetService("HttpService"):JSONDecode(response)

			if decodedResponse.message then
				-- GPT 응답을 받았다면
				MoreResponseRemote:FireClient(player, decodedResponse.message)
			else
				MoreResponseRemote:FireClient(player, "GPT 응답을 받을 수 없습니다.")
			end
		else
			warn("서버 요청 오류:", response)
		end
	else
		MoreResponseRemote:FireClient(player, "질문을 입력하세요.")
	end
end


-- 서버 코드에서 전송되는 메시지 확인
local function handleMoreCommand(player, quizId)
	-- quizId가 "new"일 경우
	if quizId == "new" then
		print("새로운 추가 설명 요청: 사용자 ID =", player.UserId) -- 디버깅 출력
		local data = { user_id = player.UserId } -- 서버로 전송할 데이터
		local success, response = sendRequest(gptApiUrl .. "/more-new", data)

		if success then
			local decodedResponse = nil
			local decodeSuccess, decodeError = pcall(function()
				decodedResponse = HttpService:JSONDecode(response)
			end)

			if decodeSuccess and decodedResponse then
				local responseMessage = decodedResponse.message or "추가 설명을 가져오는 데 실패했습니다."
				print("서버 응답 메시지:", responseMessage) -- 디버깅용 출력
				MoreResponseRemote:FireClient(player, responseMessage)
			else
				warn("서버 응답 디코딩 실패:", decodeError)
				MoreResponseRemote:FireClient(player, "추가 설명 디코딩 실패.")
			end
		else
			warn("추가 설명 요청 실패:", response)
			MoreResponseRemote:FireClient(player, "추가 설명 요청 실패. 서버 문제일 수 있습니다.")
		end
	else
		-- 특정 퀴즈 ID에 대한 추가 설명 처리
		print("퀴즈 ID에 대한 설명 요청:", quizId) -- 디버깅용 출력
		local data = { user_id = player.UserId, quiz_id = quizId }
		local success, response = sendRequest(gptApiUrl .. "/more", data)

		if success then
			local decodedResponse = HttpService:JSONDecode(response)
			local responseMessage = decodedResponse.message or "해당 문제에 대한 설명이 없습니다."
			print("서버 응답 메시지:", responseMessage) -- 디버깅용 출력
			MoreResponseRemote:FireClient(player, responseMessage)
		else
			warn("GPT 추가 설명 요청 오류:", response)
			MoreResponseRemote:FireClient(player, "추가 설명 요청 실패.")
		end
	end
end

local function handleStudyCommand(player, args)
	-- 유닛 번호를 그대로 사용 (숫자인지 확인하지 않음)
	local unit_number = args

	-- unit_number가 nil이 아니면
	if unit_number then
		local data = {
			user_id = player.UserId,
			unit_number = unit_number  -- 그대로 전달
		}

		local success, response = sendRequest(mainApiUrl .. "/get-wrong-questions", data)

		if success then
			local decodedResponse = game:GetService("HttpService"):JSONDecode(response)

			if decodedResponse.message then
				-- '틀린 문제가 없습니다'와 같은 메시지를 받으면
				MoreResponseRemote:FireClient(player, "틀린 문제가 없습니다.")
			else
				-- 틀린 문제를 받았다면
				local message = "틀린 문제 목록:\n"
				for _, question in ipairs(decodedResponse) do
					message = message .. "퀴즈 타입: " .. question.quiz_type .. ", 퀴즈 ID: " .. question.quiz_id .. "\n"
				end
				MoreResponseRemote:FireClient(player, message)
			end
		else
			warn("서버 요청 오류:", response)
		end
	else
		MoreResponseRemote:FireClient(player, "유효한 유닛 번호를 입력하세요.")
	end
end

local function handleQuizCommand(player, args)
	-- 유닛 번호를 명령 인수에서 추출
	local unit_number = args

	-- unit_number가 존재하면 서버에 요청 보내기
	if unit_number then
		local data = {
			unit_number = unit_number  -- 유닛 번호 전달
		}

		-- 서버에 요청 보내기
		local success, response = sendRequest(mainApiUrl .. "/get-quiz", data)

		if success then
			local decodedResponse = game:GetService("HttpService"):JSONDecode(response)

			if decodedResponse.message then
				-- '해당 유닛에 퀴즈가 없습니다.' 메시지를 받으면
				MoreResponseRemote:FireClient(player, decodedResponse.message)
			else
				-- 퀴즈를 받았다면
				local message = "퀴즈 목록:\n"
				for _, quiz in ipairs(decodedResponse) do
					message = message .. "퀴즈 ID: " .. quiz.quiz_id .. ", 질문: " .. quiz.question .. "\n"
				end
				MoreResponseRemote:FireClient(player, message)
			end
		else
			warn("서버 요청 오류:", response)
		end
	else
		MoreResponseRemote:FireClient(player, "유효한 유닛 번호를 입력하세요.")
	end
end


-- handleAddQuizCommand 수정: 퀴즈 추가 요청
local function handleAddQuizCommand(player, quizId, difficulty)
	local data = { user_id = player.UserId, quiz_id = quizId, difficulty_level = difficulty }
	local success, response = sendRequest(gptApiUrl .. "/add-quiz", data)

	if success then
		local decodedResponse = HttpService:JSONDecode(response)
		local addMessage = decodedResponse.message or "퀴즈 추가에 실패했습니다."
		local responseMessage = "새로 추가된 퀴즈: " .. (decodedResponse.question or addMessage)

		-- BindableEvent를 통해 클라이언트로 전송 (말풍선 사용 X)
		MoreResponseRemote:FireClient(player, responseMessage)
	else
		warn("퀴즈 추가 요청 오류:", response)
	end
end

-- 퀴즈 정답 확인 요청 함수
local function handleCheckAnswer(player)
	local data = { user_id = player.UserId }
	local success, response = sendRequest(mainApiUrl .. "/check-answer", data)

	if success then
		local decodedResponse = HttpService:JSONDecode(response)
		local question = decodedResponse.question
		local correctAnswer = decodedResponse.correct_answer

		-- 정답 및 질문을 클라이언트로 전송
		CheckAnswerRemote:FireClient(player, question, correctAnswer)
	else
		warn("정답 가져오기 요청 오류:", response)
		CheckAnswerRemote:FireClient(player, "퀴즈를 가져오는 데 실패했습니다.", "")
	end
end

CheckAnswerRemote.OnServerEvent:Connect(function(player)
	handleCheckAnswer(player)
end)


-- 채팅 명령어 처리
local function onPlayerChatted(player, message)
	-- 명령어와 인수 추출 (모두 소문자로 변환)
	local command, args = message:match("(%S+)%s*(.*)")
	command = command and command:lower() or "" -- 명령어를 소문자로 변환
	args = args and args:lower() or ""         -- 인수를 소문자로 변환

	if command == "npc!" then
		handleNpcCommand(player, args)
	elseif command == "study!" then
		handleStudyCommand(player, args)
	elseif command == "more!" then
		handleMoreCommand(player, args)
	elseif command == "quiz!" then
		handleQuizCommand(player, args)
	elseif command == "add!" then
		local quizId, difficulty = args:match("(%S+)%s+(%S+)")
		handleAddQuizCommand(player, quizId, difficulty)
	else
		sendChatMessage("알 수 없는 명령어입니다. 사용 가능한 명령어: npc!, study!, more!, quiz!, add!")
	end
end


-- 플레이어가 게임에 들어올 때 이벤트 연결
Players.PlayerAdded:Connect(function(player)
	print(player.UserId .. "가 게임에 입장했습니다.")
	player.Chatted:Connect(function(message)
		onPlayerChatted(player, message)
	end)

	-- 점수 및 퀴즈 시도 결과 이벤트 처리
	ScoreEventBindable.Event:Connect(function(score)
		sendScore(player.UserId, score)
	end)

	AttemptEventBindable.Event:Connect(function(quizId, isCorrect)
		sendQuizAttempt(player.UserId, quizId, isCorrect)
	end)

end)

