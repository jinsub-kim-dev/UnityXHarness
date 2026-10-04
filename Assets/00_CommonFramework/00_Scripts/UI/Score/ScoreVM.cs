using System;
using O2un.Score;
using R3;

namespace O2un.UI
{
    public sealed class ScoreVM : IDisposable
    {
        private readonly ReactiveProperty<int> _score = new();
        public ReadOnlyReactiveProperty<int> Score => _score;
        private readonly CompositeDisposable _disposables = new();

        public ScoreVM(IScoreReader score)
        {
            score.Score.Subscribe(x =>
            {
                _score.Value = x;
            }).AddTo(_disposables);
        }

        public void Dispose()
        {
            _disposables.Dispose();
            _score.Dispose();
        }
    }
}
