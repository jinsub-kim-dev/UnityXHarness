using O2un.DataStore;
using UnityEngine;
using VContainer;

namespace O2un.UI
{
    public class HudContext : MonoBehaviour
    {
        [SerializeField] private HudView _view;
        private HudVM _vm;

        [Inject]
        public void Inject(IUIReader reader, IPlayerDataReader playerData)
        {
            _vm = new HudVM(reader, playerData);
            _view.Bind(_vm);
        }

        void OnDestroy()
        {
            _vm?.Dispose();
        }
    }
}

