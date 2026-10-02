using R3;
using UnityEngine;
using VContainer;

namespace O2un.UI
{
    public interface ILoadingSource
    {
        ReadOnlyReactiveProperty<float> LoadingProgress { get; }
    }

    public class LoadingContext : MonoBehaviour
    {
        [SerializeField] private LoadingView _view;
        private LoadingVM _vm;

        [Inject]
        public void Inject(ILoadingSource source)
        {
            _vm = new(source);
            _view.Bind(_vm);
        }

        void Oestroy()
        {
            _vm?.Dispose();            
        }
    }
}
