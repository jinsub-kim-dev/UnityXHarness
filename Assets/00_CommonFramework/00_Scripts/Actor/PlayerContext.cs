using O2un.Input;
using UnityEngine;
using VContainer;

namespace O2un.Actor
{
    public sealed class PlayerContext : MonoBehaviour
    {
        [SerializeField] private PlayerView _view;
        private PlayerActor _actor;

        [Inject] 
        public void Init(IInputReader _input)
        {
            _actor = new PlayerActor(_input, _view);
            _actor.Init();
        }

        private void OnDestroy()
        {
            _actor?.Dispose();
        }
        
    }
}
