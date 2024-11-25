local Englishs = {
	{
		Quiz = "한 로켓 엔진의 연료 소모율이 100 kg/s이고, 배기 속도 ve 가 3,000 m/s일 때, 이 엔진이 생성하는 추력은 얼마입니까?",
		A1 = "300,000 N",
		A2 = "200,000 N",
		A3 = "400,000 N",
		A4 = "500,000 N",
		Score = 30,
		quiz_id = "0-1" -- 퀴즈 ID 추가
	},
	{
		Quiz = "초속도가 3000 m/s인 로켓이 초기 질량 1000 kg에서 연료를 모두 소모한 후 400 kg이 되었습니다. 이 로켓의 델타 V는 얼마입니까? (g0 = 9.8 m/s^2)",
		A1 = "4,160 m/s",
		A2 = "3,200 m/s",
		A3 = "5,200 m/s",
		A4 = "6,000 m/s",
		Score = 30,
		quiz_id = "0-2" -- 퀴즈 ID 추가
	},
	{
		Quiz = "한 로켓 엔진의 배기 속도가 2,500 m/s일 때, 이 엔진의 초속도는 얼마입니까? (g0 = 9.8 m/s^2)",
		A1 = "255 s",
		A2 = "220 s",
		A3 = "265 s",
		A4 = "300 s",
		Score = 30,
		quiz_id = "0-3" -- 퀴즈 ID 추가
	}
}


local QuizFrame = script.Parent
local PlayerDialog = QuizFrame:WaitForChild("Dialog")

local MainFrame = QuizFrame.Parent:WaitForChild("Frame")
local QuizAIDialog = MainFrame:WaitForChild("Dialog")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- BindableEvent 생성 확인 및 가져오기
local ScoreEventBindable = ReplicatedStorage:FindFirstChild("ScoreEventBindable")
if not ScoreEventBindable then
	ScoreEventBindable = Instance.new("BindableEvent")
	ScoreEventBindable.Name = "ScoreEventBindable"
	ScoreEventBindable.Parent = ReplicatedStorage
end

local AttemptEventBindable = ReplicatedStorage:FindFirstChild("AttemptEventBindable")
if not AttemptEventBindable then
	AttemptEventBindable = Instance.new("BindableEvent")
	AttemptEventBindable.Name = "AttemptEventBindable"
	AttemptEventBindable.Parent = ReplicatedStorage
end

local Players = game:GetService("Players")
-- END

function TextStart(message1)
	for i = 1, #message1 do
		QuizAIDialog.Text = string.sub(message1, 1, i)
		task.wait()
	end
end

function TextStart2(message1)
	for i = 1, #message1 do
		PlayerDialog.Text = string.sub(message1, 1, i)
		task.wait()
	end
end

local Event = game.ReplicatedStorage:WaitForChild("StartEvent")
local Folder2 = QuizFrame:WaitForChild("Folder")

local Debounce = false
local p = 10 --기본 점수
local k = 0 --맞춘 문제 수

local QuizNum = 3 --퀴즈 수 적어주세요.

local d = 0 --문제 수 카운트다운
local s = 0

local lA = nil

Event.OnServerEvent:Connect(function(player)
	if not Debounce then
		Debounce = true
		PlayerDialog.Text = "..."
		PlayerDialog.Visible = false

		while d == s and d ~= 3 do
			d += 1

			local b = 1
			for i, v in pairs(Folder2:GetChildren()) do
				v.Name = b
				b += 1
			end

			QuizFrame.Visible = true

			local Folder = Folder2:GetChildren()

			local RandomQuiz = Englishs[d]
			QuizAIDialog.Text = RandomQuiz.Quiz

			local RandomAnswer = Folder[math.random(1, #Folder)]
			RandomAnswer.Answer.Text = RandomQuiz.A1

			local pf = true
			local o = 0

			for i, v in pairs(Folder) do
				if v.Name ~= RandomAnswer.Name then
					if o == 0 then
						v.Answer.Text = RandomQuiz.A2
					elseif o == 1 then
						v.Answer.Text = RandomQuiz.A3
					elseif o == 2 then
						v.Answer.Text = RandomQuiz.A4
					end

					QuizFrame.Folder.Visible = true

					v.MouseButton1Click:Connect(function()
						if pf then
							pf = false
							lA = false
							QuizFrame.Visible = false

							TextStart("아쉽게도 틀렸습니다. 정답은 ["..RandomAnswer.Name..". "..RandomQuiz.A1.."] 입니다!")
							wait(3)

							-- 틀렸을 때 서버에 결과 전송
							AttemptEventBindable:Fire(RandomQuiz.quiz_id, false)
							-- END

							s += 1

							return
						end
					end)

					o += 1
				end
			end

			RandomAnswer.MouseButton1Click:Connect(function()
				if pf then
					pf = false
					p += RandomQuiz.Score
					k += 1
					lA = true
					QuizFrame.Visible = false
					TextStart("대단하네요. 정답입니다!")
					wait(3)

					-- 맞았을 때 서버에 결과 전송
					AttemptEventBindable:Fire(RandomQuiz.quiz_id, true)
					-- END


					s += 1

					return
				end
			end)

			repeat
				wait()
			until d == s
		end

		wait(1)

		--결과
		ScoreEventBindable:Fire(p)
		--END
		QuizFrame.Folder.Visible = false
		PlayerDialog.Visible = true

		TextStart("퀴즈를 다 풀었습니다. 3개의 문제 중 "..k.."개를 맞춰 기본 점수 10점을 더해 "..p.."점입니다.")
		wait(4)


		TextStart("퀴즈를 마치겠습니다.")
		wait(4)

		PlayerDialog.Text = "..."
	end
end)
