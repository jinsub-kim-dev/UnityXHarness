using System;
using O2un.Input;
using R3;
using UnityEngine;

namespace O2un.Actor
{
    public sealed class PlayerMover : IDisposable
    {
        private float _speed = 5f;
        private float _jumpForce = 8f;

        private readonly ReactiveProperty<Vector3> _velocity = new();
        private readonly Subject<float> _jumpImpulse = new();
        private readonly CompositeDisposable _disposables = new();

        public ReadOnlyReactiveProperty<Vector3> Velocity => _velocity;
        public Observable<float> JumpImpulse => _jumpImpulse;

        public PlayerMover(IInputReader input)
        {
            input.Move.Subscribe(v => _velocity.Value = new Vector3(v.x * _speed, 0, v.y * _speed)).AddTo(_disposables);
            input.IsJumpPressed.Subscribe(_ => _jumpImpulse.OnNext(_jumpForce)).AddTo(_disposables);
        }

        public void Dispose()
        {
            _disposables.Dispose();
            _velocity.Dispose();
            _jumpImpulse.Dispose();
        }
    }
}