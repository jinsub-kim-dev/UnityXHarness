using System;
using R3;
using UnityEngine;

namespace O2un.DataStore
{
    public interface IPlayerDataReader
    {
        public ReadOnlyReactiveProperty<int> CurrentHP { get; }
        public ReadOnlyReactiveProperty<int> MaxHP { get; }
    }

    public interface IPlayerDataWriter
    {
        public void Vary(int hp);
        public void SetCurrentHP(int hp);
    }

    public sealed class PlayerDataStore : IPlayerDataReader, IPlayerDataWriter, IDisposable
    {
        private readonly ReactiveProperty<int> _hp = new();
        private readonly ReactiveProperty<int> _maxHP = new(100);

        public ReadOnlyReactiveProperty<int> CurrentHP => _hp;
        public ReadOnlyReactiveProperty<int> MaxHP => _maxHP;

        public void Vary(int hp)
        {
            _hp.Value += hp;
            _hp.Value = Mathf.Clamp(CurrentHP.CurrentValue, 0, MaxHP.CurrentValue);
        }

        public void SetCurrentHP(int hp)
        {
            _hp.Value = hp;
        }

        public void Dispose()
        {
            _hp.Dispose();
            _maxHP.Dispose();
        }

        
    }
}