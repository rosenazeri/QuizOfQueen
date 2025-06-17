from typing import Optional
class Question:
    def __init__(self, question_id: int, text: str, optionA: str, optionB: str,
                 optionC: str, optionD: str, correct_option: str,
                 difficulty_level: str, category_id: Optional[int],
                 author_id: Optional[int], status: str):
        self.question_id = question_id
        self.text = text
        self.optionA = optionA
        self.optionB = optionB
        self.optionC = optionC
        self.optionD = optionD
        self.correct_option = correct_option  # 'A', 'B', 'C', 'D'
        self.difficulty_level = difficulty_level
        self.category_id = category_id
        self.author_id = author_id
        self.status = status
