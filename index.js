import express from "express";
import bodyParser from "body-parser";
import axios from "axios";
import dotenv from "dotenv";
import mysql from "mysql2/promise"; // promise 버전 사용

dotenv.config();

const app = express();
const port = 3000;

// POST 요청의 body를 JSON으로 파싱
app.use(bodyParser.json());

const dbConfig = {
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE,
};

// 데이터베이스 연결 함수
async function connectToDatabase() {
    try {
        const connection = await mysql.createConnection(dbConfig);
        console.log("데이터베이스에 연결되었습니다.");
        return connection;
    } catch (err) {
        console.error("데이터베이스 연결 실패:", err);
        throw err;
    }
}

// /chat 엔드포인트
app.post("/chat", async (req, res) => {
    const userMessage = req.body.message;

    if (!userMessage) {
        return res.status(400).json({ message: "메시지가 없습니다." });
    }

    try {
        const response = await axios.post(
            "https://api.openai.com/v1/chat/completions",
            {
                model: "gpt-3.5-turbo",
                messages: [{ role: "user", content: userMessage }],
                max_tokens: 300,
            },
            {
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
                },
            }
        );

        const gptResponse = response.data.choices[0].message.content;
        res.json({ message: gptResponse });
    } catch (error) {
        console.error("GPT API 요청 중 오류 발생:", error.response ? error.response.data : error.message);
        res.status(500).json({ message: "GPT 응답 중 오류 발생." });
    }
});

app.post('/chat/more', async (req, res) => {
    const { user_id, quiz_id } = req.body;
    console.log(req.body);

    if (!user_id || !quiz_id) {
        return res.status(400).json({ message: "user_id와 quiz_id가 필요합니다." });
    }

    // 데이터베이스에서 해당 문제 ID가 틀린 문제인지 확인
    const query = `
        SELECT Q.quiz_type, Q.Question, Q.A1, Q.A2, Q.A3, Q.A4
        FROM Answers A
        JOIN Quiz Q ON A.quiz_id = Q.quiz_id
        WHERE A.student_id = ? AND Q.quiz_id = ?
    `;

    const connection = await connectToDatabase();
    if (!connection) return res.status(500).send("데이터베이스 연결 실패");

    try {
        const [results] = await connection.execute(query, [user_id, quiz_id]);

        if (results.length > 0) {
            const { quiz_type, Question, A1, A2, A3, A4 } = results[0];

            // GPT에게 질문 메시지 생성
            const questionMessage = `다음 문제를 풀기 위한 설명을 자세하게 제공해줘:\n\n질문: ${Question}\n1) ${A1}\n2) ${A2}\n3) ${A3}\n4) ${A4}`;

            try {
                const response = await axios.post(
                    "https://api.openai.com/v1/chat/completions",
                    {
                        model: "gpt-3.5-turbo",
                        messages: [{ role: "user", content: questionMessage }],
                        max_tokens: 300,
                    },
                    {
                        headers: {
                            "Content-Type": "application/json",
                            Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
                        },
                    }
                );

                const gptResponse = response.data.choices[0].message.content;
                res.json({ message: gptResponse });
            } catch (error) {
                console.error("GPT API 요청 중 오류 발생:", error.response ? error.response.data : error.message);
                res.status(500).json({ message: "GPT 응답 중 오류 발생." });
            }
        } else {
            // 문제 ID가 틀린 문제 목록에 없으면 처리
            res.status(404).json({ message: "해당 문제 ID에 대한 설명은 불가능합니다." });
        }
    } catch (error) {
        console.error("쿼리 실행 중 오류:", error);
        res.status(500).json({ message: '서버 오류 발생', error: error.message });
    } finally {
        await connection.end();
    }
});

app.post("/chat/more-new", async (req, res) => {
    const { user_id } = req.body;

    if (!user_id) {
        return res.status(400).json({ message: "user_id가 필요합니다." });
    }

    const query = `
        SELECT question
        FROM Additional_Quiz
        WHERE student_id = ?
    `;

    const connection = await connectToDatabase();
    if (!connection) return res.status(500).send("데이터베이스 연결 실패");

    try {
        // `Additional_Quiz`에서 student_id로 질문 가져오기
        const [results] = await connection.execute(query, [user_id]);

        if (results.length === 0) {
            return res.status(404).json({ message: "해당 학생에 대한 추가 퀴즈가 없습니다." });
        }

        const { question } = results[0];

        // GPT에게 질문 요청
        const gptResponse = await axios.post(
            "https://api.openai.com/v1/chat/completions",
            {
                model: "gpt-3.5-turbo",
                messages: [{ role: "user", content: question }],
                max_tokens: 300,
            },
            {
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
                },
            }
        );

        const gptAnswer = gptResponse.data.choices[0].message.content.trim();
        res.json({ message: gptAnswer });
    } catch (error) {
        console.error("GPT API 요청 중 오류 발생:", error.response ? error.response.data : error.message);
        res.status(500).json({ message: "GPT 응답 중 오류 발생." });
    } finally {
        await connection.end();
    }
});


// 특정 유닛의 퀴즈 목록을 가져오는 API
app.post("/get-quiz", async (req, res) => {
    const { unit_number } = req.body;

    if (!unit_number) {
        return res.status(400).json({ message: "unit_number가 필요합니다." });
    }

    const query = `
        SELECT quiz_id, Question
        FROM Quiz
        WHERE unit_number = ?
    `;

    const connection = await connectToDatabase();
    if (!connection) return res.status(500).send("데이터베이스 연결 실패");

    try {
        const [results] = await connection.execute(query, [unit_number]);

        if (results.length > 0) {
            const quizzes = results.map(row => ({
                quiz_id: row.quiz_id,
                question: row.Question
            }));
            console.log(quizzes)
            res.json(quizzes);
        } else {
            res.json({ message: "해당 유닛에 퀴즈가 없습니다." });
        }
    } catch (error) {
        console.error("쿼리 실행 중 오류:", error);
        res.status(500).json({ message: "서버 오류 발생", error: error.message });
    } finally {
        await connection.end();
    }
});


// 점수 저장 엔드포인트
app.post("/save-score", async (req, res) => {
    const { user_id, score } = req.body;
    console.log(req.body);

    if (user_id === undefined || score === undefined) {
        return res.status(400).send("user_id 또는 score가 유효하지 않습니다.");
    }

    const connection = await connectToDatabase();
    if (!connection) return res.status(500).send("데이터베이스 연결 실패");

    try {
        const [rows] = await connection.execute(
            "SELECT * FROM Students WHERE student_id = ?",
            [user_id]
        );

        if (rows.length > 0) {
            await connection.execute(
                "UPDATE Students SET total_score = ? WHERE student_id = ?",
                [score, user_id]
            );
            return res.status(200).send("점수 업데이트 성공");
        } else {
            await connection.execute(
                "INSERT INTO Students (student_id, total_score) VALUES (?, ?)",
                [user_id, score]
            );
            return res.status(200).send("점수 저장 성공");
        }
    } catch (err) {
        console.error("점수 저장 오류:", err);
        return res.status(500).send("점수 저장 실패");
    } finally {
        await connection.end();
    }
});

// 퀴즈 시도 결과 저장 엔드포인트
app.post("/save-attempt", async (req, res) => {
    const { user_id, quiz_id, is_correct } = req.body;
    console.log(user_id);
    console.log(quiz_id);
    console.log(is_correct);
    console.log(req.body);

    if (user_id === undefined || quiz_id === undefined || is_correct === undefined) {
        return res.status(400).send("user_id, quiz_id 또는 is_correct가 유효하지 않습니다.");
    }

    const connection = await connectToDatabase();
    if (!connection) return res.status(500).send("데이터베이스 연결 실패");

    try {
        const [studentRows] = await connection.execute(
            "SELECT * FROM Students WHERE student_id = ?",
            [user_id]
        );

        if (studentRows.length === 0) {
            // student_id가 없으면 추가
            await connection.execute(
                "INSERT INTO Students (student_id, total_score) VALUES (?, 0)",
                [user_id]
            );
        }

        const [quizRows] = await connection.execute(
            "SELECT unit_number FROM Quiz WHERE quiz_id = ?",
            [quiz_id]
        );

        if (quizRows.length === 0) {
            return res.status(404).send("해당 퀴즈가 존재하지 않습니다.");
        }
        const unit_number = quizRows[0].unit_number;

        const [rows] = await connection.execute(
            "SELECT * FROM Answers WHERE student_id = ? AND quiz_id = ?",
            [user_id, quiz_id]
        );

        if (rows.length > 0) {
            await connection.execute(
                "UPDATE Answers SET is_correct = ?, unit_number = ? WHERE student_id = ? AND quiz_id = ?",
                [is_correct, unit_number, user_id, quiz_id]
            );
            return res.status(200).send("퀴즈 시도 업데이트 성공");
        } else {
            await connection.execute(
                "INSERT INTO Answers (student_id, quiz_id, is_correct, unit_number) VALUES (?, ?, ?, ?)",
                [user_id, quiz_id, is_correct, unit_number]
            );
            return res.status(200).send("퀴즈 시도 저장 성공");
        }
    } catch (err) {
        console.error("퀴즈 시도 저장 오류:", err);
        return res.status(500).send("퀴즈 시도 저장 실패");
    } finally {
        await connection.end();
    }
});

// 틀린 문제 가져오기 API
app.post('/get-wrong-questions', async (req, res) => {
    const { user_id, unit_number } = req.body;
    console.log(req.body);

    // 사용자 ID와 유닛 번호가 유효한지 확인
    if (!user_id || !unit_number) {
        return res.status(400).json({ message: "user_id 또는 unit_number가 필요합니다." });
    }


    // 쿼리: 틀린 문제만 가져오기 (user_id와 unit_number로 필터링)
    const query = `
        SELECT Q.quiz_type, Q.quiz_id, Q.difficulty_level
        FROM Answers A
        JOIN Quiz Q ON A.quiz_id = Q.quiz_id
        WHERE A.student_id = ? AND A.is_correct = false AND A.unit_number = ?
    `;

    console.log(query)
    const connection = await connectToDatabase();
    if (!connection) return res.status(500).send("데이터베이스 연결 실패");

    try {
        // 쿼리 실행: 해당 유저의 틀린 문제 가져오기
        const [results] = await connection.execute(query, [user_id, unit_number]);

        if (results.length > 0) {
            // 틀린 문제 목록 반환
            const wrongQuestions = results.map(row => ({
                quiz_type: row.quiz_type,
                quiz_id: row.quiz_id,
                difficulty_level: row.difficulty_level
            }));

            res.json(wrongQuestions);
        } else {
            // 틀린 문제가 없을 경우
            res.json({ message: '틀린 문제가 없습니다.' });
        }
    } catch (error) {
        console.error("쿼리 실행 중 오류:", error);
        res.status(500).json({ message: '서버 오류 발생', error: error.message });
    } finally {
        await connection.end();
    }
});


app.post("/chat/add-quiz", async (req, res) => {
    const { user_id, quiz_id, difficulty_level } = req.body;
    if (!user_id || !quiz_id || !difficulty_level) {
        return res.status(400).json({ message: "user_id, quiz_id, 또는 difficulty_level이 필요합니다." });
    }

    // difficulty_level 유효성 검사
    if (!["상", "중", "하"].includes(difficulty_level)) {
        return res.status(400).json({ message: "difficulty_level은 '상', '중', 또는 '하' 여야 합니다." });
    }

    const connection = await connectToDatabase();
    if (!connection) return res.status(500).send("데이터베이스 연결 실패");

    try {
        // 기존 퀴즈 조회
        const query = `
            SELECT Question, A1, A2, A3, A4
            FROM Quiz
            WHERE quiz_id = ?
        `;
        const [quizResults] = await connection.execute(query, [quiz_id]);

        if (quizResults.length === 0) {
            return res.status(404).json({ message: "해당 퀴즈 ID가 존재하지 않습니다." });
        }

        const { Question, A1, A2, A3, A4 } = quizResults[0];

        // GPT에게 새로운 문제를 생성하기 위한 메시지 구성
        const difficultyMessage = difficulty_level === "상" ? "어렵게" : difficulty_level === "중" ? "비슷한 난이도" : "쉽게";
        const gptQuestionMessage = `위와 비슷한 문제를 ${difficultyMessage} 만들어줘:\n\n질문: ${Question}\n선택지: ${A1}, ${A2}, ${A3}, ${A4}`;

        // 새로운 문제 생성 요청
        const gptResponse = await axios.post(
            "https://api.openai.com/v1/chat/completions",
            {
                model: "gpt-3.5-turbo",
                messages: [{ role: "user", content: gptQuestionMessage }],
                max_tokens: 150,
            },
            {
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
                },
            }
        );

        const generatedQuestion = gptResponse.data.choices[0].message.content.trim();

        // GPT에게 generatedQuestion의 정답 요청
        const gptAnswerMessage = `다음 질문에 대한 정답만 [정답 : ]의 형식으로알려줘:\n\n${generatedQuestion}`;
        const gptAnswerResponse = await axios.post(
            "https://api.openai.com/v1/chat/completions",
            {
                model: "gpt-3.5-turbo",
                messages: [{ role: "user", content: gptAnswerMessage }],
                max_tokens: 50,
            },
            {
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
                },
            }
        );

        const generatedAnswer = gptAnswerResponse.data.choices[0].message.content.trim();

        // 기존 퀴즈 저장 또는 업데이트
        const insertQuery = `
            INSERT INTO Additional_Quiz (student_id, question, correct_answer)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE question = VALUES(question), correct_answer = VALUES(correct_answer)
        `;
        await connection.execute(insertQuery, [user_id, generatedQuestion, generatedAnswer]);

        // 추가된 퀴즈와 정답을 응답으로 보내기
        res.status(200).json({ message: "퀴즈가 추가되었습니다.", question: generatedQuestion, correct_answer: generatedAnswer });
    } catch (error) {
        console.error("퀴즈 추가 중 오류:", error);
        res.status(500).json({ message: "퀴즈 추가 중 오류 발생." });
    } finally {
        await connection.end();
    }
});

// /check-answer 엔드포인트
app.post("/check-answer", async (req, res) => {
    const { user_id } = req.body;

    if (!user_id) {
        return res.status(400).json({ error: "user_id를 입력해주세요." });
    }

    const connection = await connectToDatabase();
    if (!connection) return res.status(500).send("데이터베이스 연결 실패");

    try {
        // 가장 최근에 추가된 퀴즈를 가져오는 쿼리
        const query = `
            SELECT correct_answer 
            FROM Additional_Quiz 
            WHERE student_id = ? 
        `;

        const [results] = await connection.execute(query, [user_id]);

        if (results.length === 0) {
            return res.status(404).json({ message: "해당 사용자의 퀴즈를 찾을 수 없습니다." });
        }

        const {correct_answer } = results[0];

        // 정답 및 문제를 반환
        res.json({
            correct_answer,
            message: "정답을 가져왔습니다."
        });
    } catch (err) {
        console.error("DB 조회 오류:", err);
        return res.status(500).json({ error: "데이터베이스 오류" });
    } finally {
        await connection.end();
    }
});


// 서버 실행
app.listen(port, () => {
    console.log(`서버가 http://localhost:${port} 에서 실행 중입니다.`);
});
