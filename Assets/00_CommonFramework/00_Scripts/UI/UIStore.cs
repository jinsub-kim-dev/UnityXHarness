using System;
using System.Collections.Generic;
using R3;
using UnityEngine;

namespace O2un.DataStore
{
    public enum UIType
    {
        HUD,
    }

    public interface IUIReader
    {
        public ReadOnlyReactiveProperty<bool> GetVisible(UIType type);
    }

    public interface IUIWriter
    {
        void Show(UIType type);
        void Hide(UIType type);
    }

    public sealed class UIStore : IUIReader, IUIWriter, IDisposable
    {
        private readonly Dictionary<UIType, ReactiveProperty<bool>> _uiStore = new()
        {
            { UIType.HUD, new() },
        };

        public ReadOnlyReactiveProperty<bool> GetVisible(UIType type) => _uiStore[type];

        public void Show(UIType type) => _uiStore[type].Value = true;
        public void Hide(UIType type) => _uiStore[type].Value = false;

        public void Dispose()
        {
            foreach(var ui in _uiStore.Values)
            {
                ui.Dispose();
            }
        }
    }
}