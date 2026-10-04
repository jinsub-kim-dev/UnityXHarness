using R3;

namespace O2un.Game
{
    public enum GameState
    {
        Ready,
        Playing,
        Paused,
        GameOver,
    }

    public interface IGameFlow
    {
        ReadOnlyReactiveProperty<GameState> State { get; }

        void StartGame();
        void Pause();
        void Resume();
        void Restart();
    }
}
