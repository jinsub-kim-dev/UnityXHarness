using Cysharp.Threading.Tasks;
using O2un.Data;
using O2un.DI;
using R3;
using UnityEngine;

namespace O2un.Manager
{
    public sealed class OptionManager : IRootTask
    {
        private readonly DataProvider _dataProvider;

        public OptionManager(DataProvider dataProvider)
        {
            _dataProvider = dataProvider;
        }

        private OptionsData _data;
 
        public void Save(OptionsData data) => _dataProvider.Save(data);

        public async UniTask WaitUntilReadyAsync()
        {
            _data = await _dataProvider.Load<OptionsData>();
        }
    }
}