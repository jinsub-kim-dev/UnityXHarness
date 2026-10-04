using R3;

namespace O2un.Score
{
    public interface IScoreReader
    {
        ReadOnlyReactiveProperty<int> Score { get; }
    }

    public interface IScoreWriter
    {
        void AddScore(int basePoint);
    }
}
