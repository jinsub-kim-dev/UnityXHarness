using System;
using UnityEngine;

namespace O2un.Data
{
    [Serializable]
    public sealed class OptionsData
    {
        public float MusicVolume = 1.0f;
        public float SfxVolume = 1.0f;
        public string Language = "ko";
    }
}