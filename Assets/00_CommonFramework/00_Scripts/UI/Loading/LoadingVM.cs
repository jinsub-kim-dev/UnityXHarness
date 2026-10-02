using System;
using R3;
using UnityEngine;

namespace O2un.UI
{
    public sealed class LoadingVM : IDisposable
    {
        public ReadOnlyReactiveProperty<float> Progress { get; }
        public LoadingVM(ILoadingSource source)
        {
            Progress = source.LoadingProgress;
        }

        public void Dispose()
        {
            
        }
    }
}
