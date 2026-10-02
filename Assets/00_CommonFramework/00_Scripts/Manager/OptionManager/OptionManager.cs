using Cysharp.Threading.Tasks;
using O2un.Data;
using UnityEngine;

namespace O2un.Manager
{
    public sealed class OptionManager
    {
        private readonly DataProvider _dataProvider;

        public OptionManager(DataProvider dataProvider)
        {
            _dataProvider = dataProvider;
        }

        private OptionsData _data;
        public void Load()
        {
            _dataProvider.Load<OptionsData>().ContinueWith(x =>
            {
                _data = x;
            });
        } 
        public void Save(OptionsData data) => _dataProvider.Save(data);
    }
}