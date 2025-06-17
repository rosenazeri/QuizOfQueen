class PlayerStatus:
    def __init__(self, user_id: int, total_games: int, games_won: int,
                 games_lost: int, accuracy: float, xp: int):
        self.user_id = user_id
        self.total_games = total_games
        self.games_won = games_won
        self.games_lost = games_lost
        self.accuracy = accuracy
        self.xp = xp