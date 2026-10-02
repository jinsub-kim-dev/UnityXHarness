using System;
using O2un.DataStore;
using R3;
using UnityEngine;

namespace O2un.UI
{
    public sealed class HudVM : IDisposable
    {
        public ReadOnlyReactiveProperty<bool> IsVisible { get; }
        private readonly ReactiveProperty<float> _currentHP = new();
        public ReadOnlyReactiveProperty<float> CurrentHP => _currentHP;
        private readonly CompositeDisposable _disposables = new();

        public HudVM(IUIReader uiReader, IPlayerDataReader playerData)
        {
            IsVisible = uiReader.GetVisible(UIType.HUD);
            playerData.CurrentHP.Subscribe(x => 
            { 
                _currentHP.Value = (float)x / playerData.MaxHP.CurrentValue;
            }).AddTo(_disposables);
            
        }

        public void Dispose()
        {
            _disposables.Dispose();
            _currentHP.Dispose();
        }
    }
}