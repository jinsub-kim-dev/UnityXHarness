using System;
using O2un.Input;
using R3;
using UnityEngine;

namespace O2un.Actor
{
    public sealed class PlayerActor : IDisposable
    {
        private readonly PlayerMover _mover;
        private readonly PlayerView _view;
        private readonly CompositeDisposable _disposables = new();

        public PlayerActor(IInputReader input, PlayerView view)
        {
            _view = view;
            _mover = new(input);
        }

        public void Init()
        {
            _mover.Velocity.Subscribe(v => _view.SetVelocity(v)).AddTo(_disposables);
        }
        
        public void Dispose()
        {
            _disposables.Dispose();
            _mover.Dispose();
        }
    }
}