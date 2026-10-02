using System;
using R3;
using UnityEngine;
using VContainer.Unity;

namespace O2un.Input
{
    public enum InputType
    {
        Player,
        UI
    }

    public sealed class InputManager : IInputReader, IInitializable, IDisposable
    {
        public ReadOnlyReactiveProperty<Vector2> Move => _playerInput.Move;
        public Observable<Unit> IsJumpPressed => _playerInput.Jump;

        private readonly GameInput _inputActions = new();
        private readonly PlayerInputModule _playerInput = new();
        private readonly UIInputModule _uiInput = new();

        public void Initialize()
        {
            _inputActions.Player.SetCallbacks(_playerInput);
            _inputActions.UI.SetCallbacks(_uiInput);

            _inputActions.Player.Enable();
        }

        public void SwitchInput(InputType type)
        {
            switch (type)
            {
                case InputType.Player:
                    _inputActions.UI.Disable();
                    _inputActions.Player.Enable();
                    break;
                case InputType.UI:
                    _inputActions.Player.Disable();
                    _inputActions.UI.Enable();
                    break;
            }
        }

        public void Dispose()
        {
            _inputActions.Player.SetCallbacks(null);
            _inputActions.UI.SetCallbacks(null);

            _inputActions.Disable();
            _inputActions.Dispose();
        }
    }
}
