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

        public OptionsData Load() => _dataProvider.Load<OptionsData>();
        public void Save(OptionsData data) => _dataProvider.Save(data);
    }
}