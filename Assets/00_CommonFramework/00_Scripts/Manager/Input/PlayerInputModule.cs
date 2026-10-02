using System;
using R3;
using UnityEngine;
using UnityEngine.InputSystem;

namespace O2un.Input
{
    public class PlayerInputModule : GameInput.IPlayerActions, IDisposable
    {
        private ReactiveProperty<Vector2> _move = new();
        private Subject<Unit> _jump = new();

        public ReadOnlyReactiveProperty<Vector2> Move => _move;
        public Observable<Unit> Jump => _jump;

        public void OnJump(InputAction.CallbackContext context)
        {
            if(context.performed)
            {
                _jump.OnNext(Unit.Default);
            }
        }

        public void OnMove(InputAction.CallbackContext context)
        {
            _move.Value = context.ReadValue<Vector2>();
        }

        public void Dispose()
        {
            _move.Dispose();
            _jump.Dispose();
        }
    }
}