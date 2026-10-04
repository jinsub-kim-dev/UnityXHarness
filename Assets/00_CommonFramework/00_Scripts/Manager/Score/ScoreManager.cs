using System;
using R3;

namespace O2un.Score
{
    public sealed class ScoreManager : IScoreReader, IScoreWriter, IDisposable
    {
        private readonly IScoreCalculator _calculator = new ScoreCalculateModule();
        private readonly CompositeDisposable _disposables = new();
        private readonly ReactiveProperty<int> _score;

        public ReadOnlyReactiveProperty<int> Score => _score;

        public ScoreManager()
        {
            _score = new ReactiveProperty<int>(0).AddTo(_disposables);
        }

        public void AddScore(int basePoint)
        {
            _score.Value += _calculator.Calculate(basePoint);
        }

        public void Dispose()
        {
            _disposables.Dispose();
        }
    }
}
