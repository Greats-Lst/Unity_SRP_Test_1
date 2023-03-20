using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class ShadowSettings
{
    [Min(0.001f)]
    public float MaxDistance = 100f;

    /// <summary>
    /// ������Ӱ����Fade
    /// ��ʽΪ��(1-d/m)/f  {d=depth; m=MaxDistance; f=DistanceFade}
    /// </summary>
    [Range(0.001f, 1f)]
    public float DistanceFade = 0.1f;

    public enum ETextureSize
    {
        _256 = 256,
        _512 = 512,
        _1024 = 1024,
        _2048 = 2048,
        _4096 = 4096,
        _8192 = 8192,
    }

    public enum EFilterMode
    {
        PCF2x2, PCF3x3, PCF5x5, PCF7x7,
    }

    [System.Serializable]
    public struct Directional
    {
        public ETextureSize AtlasSize;

        [Range(1, 4)]
        public int CascadeCount;

        [Range(0, 1)]
        public float CascadeRatio1, CascadeRatio2, CascadeRatio3;

        /// <summary>
        /// ���һ��������ӰFade
        /// �����ڼ���������ʹ�õ��ǰ뾶��ƽ�������������Fade��ʽҲ����Ӧ�ı仯
        /// ��ʽΪ��(1- (d*d)/(r*r)) / (1 - (1-f)*(1-f))  {d=depth; r=radius; f=CascadeFade}
        /// </summary>
        [Range(0.001f, 1f)]
        public float CascadeFade;

        public EFilterMode PCFFilterMode;

        public enum ECascadeBlendMode
        {
            Hard, Soft, Dither,
        }
        public ECascadeBlendMode CascadeBlendMode;

        public Vector3 CascadeRatio => new Vector3(CascadeRatio1, CascadeRatio2, CascadeRatio3);
    }

    public Directional DirectionalShadow = new Directional()
    {
        AtlasSize = ETextureSize._1024,
        CascadeCount = 4,
        CascadeRatio1 = 0.1f,
        CascadeRatio2 = 0.25f,
        CascadeRatio3 = 0.5f,
        CascadeFade = 0.1f,
        PCFFilterMode = EFilterMode.PCF2x2,
        CascadeBlendMode = Directional.ECascadeBlendMode.Hard,
    }; 
}
