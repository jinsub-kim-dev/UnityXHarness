using O2un.DataStore;
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
        public void Init(IInputReader input, IPlayerDataWriter playerData)
        {
            _actor = new PlayerActor(input, _view, playerData);
            _actor.Init();
        }

        private void OnDestroy()
        {
            _actor?.Dispose();
        }
        
    }
}
