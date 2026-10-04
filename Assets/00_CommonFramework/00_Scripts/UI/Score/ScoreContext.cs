using O2un.Score;
using UnityEngine;
using VContainer;

namespace O2un.UI
{
    public sealed class ScoreContext : MonoBehaviour
    {
        [SerializeField] private ScoreView _view;
        private ScoreVM _vm;

        [Inject]
        public void Inject(IScoreReader score)
        {
            _vm = new ScoreVM(score);
            _view.Bind(_vm);
        }

        private void OnDestroy()
        {
            _vm?.Dispose();
        }
    }
}
