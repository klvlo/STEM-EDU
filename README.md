# Stem Education
Using Roblox for Satellite Physics Education


# 기능 정리

# DB


## Students

- student_id : 사용자 고유 id
- total_score : 최종 점수

## Quiz

- quiz_id : 퀴즈 고유 id
- quiz_type : 퀴즈 유형
- unit_number : 퀴즈 유닛 번호
- difficulty_level : 퀴즈 난이도
- Qestion : 퀴즈 질문
- A1 ~ A4 : 퀴즈 선택지 1 ~ 4
- quiz_score : 퀴즈 점수

## Answers

- student_id : 사용자 고유 id
- quiz_id : 퀴즈 고유 id
- is_correct : 정답 여부
- unit_number : 퀴즈 유닛 번호

## Additional_Quiz

- student_id : 사용자 고유 id
- question : 추가 퀴즈 질문 & 선택지
- correct_answer : 추가 퀴즈 정답

---

# Server
- connectToDatabase : DB 연결 함수
- /chat : gpt 사용 npc와 대화 함수
- /chat/more : gpt 사용 문제 설명 함수
- /chat/more/new : gpt 사용 추가 제공 문제 설명 함수
- /get-quiz : 해당 유닛 퀴즈 목록 가져오는 함수
- /save-score : 최종 점수 저장 함수
- /save-attempt : 퀴즈 풀이 결과 저장 함수
- /get-wrong-questions : 틀린 퀴즈 문제 목록 가져오는 함수
- /chat/add-quiz : gpt 사용 추가 문제 제공 함수
- /check-answer : 추가 문제 정답 확인 함수

---

# Roblox

## Server (ServerScriptService/Script)

- SendQuizAttempt(userId, quizId, isCorrect)
    - 사용자 퀴즈 시도 결과 전송 함수

- sendScore(userId, score)
    - 사용자 퀴즈 점수 전송 함수

- onPlayerChatted
    - 사용자 채팅 내용 확인 후 명령어에 따른 함수 실행

- handleNpcCommand(player, args) : npc! 안녕?
    - npc와 대화기능 함수

- handleMoreCommand(player, quizId) : more! 0-1 / more! new
    - npc에게 퀴즈 ID(new) 전달 후 해당 퀴즈에 대한 자세한 설명 받는 함수

- handleStudyCommand(player, args) : study! 0
    - 유닛 번호를 제공하고, 해당 유닛에서 사용자가 틀린문제 목록을 가져오는 함수

- handleQuizCommand(player, args) : quiz! 0
    - 유닛 번호를 제공하고, 해당 유닛에 존재하는 퀴즈 목록을 가져오는 함수

- handleAddQuizCommand(player, quizId, difficulty) : add! 0-1 하
    - 유닛 번호와 난이도(상/중/하) 입력시 해당 퀴즈에 같은 유형의 추가 문제 (어렵게/비슷하게/쉽게) 제공

- handleCheckAnser(player)
    - submit button을 클릭시 추가 문제에 대한 정답 제공

## Quiz (StarterGui/QuizGui/Quiz/Script)

- 136번째 줄 : AttemptEventBindable:Fire(RandomQuiz.quiz_id, false)
- 160번째 줄 : AttemptEventBindable:Fire(RandomQuiz.quiz_id, true)
- 178번째 줄 : ScoreEventBindable:Fire(p)
- 각각 틀렸을 때 결과 전송, 맞았을 때 결과 전송, 최종 점수 전송 함수

## NPC 답변 창 (StarterGui/ScreenGui/LocalScript)

- 명령어를 통해 받아오는 답변 보여주기
- 추가 문제 정답 확인
