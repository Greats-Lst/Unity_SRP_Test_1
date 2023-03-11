using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

public class CustomShaderGUI : ShaderGUI
{
    bool HasProperty(string name) => FindProperty(name, m_properties, false) != null;

    bool Clipping
    {
        set => SetProperty("_Clipping", "_CLIPPING", value);
    }

    bool HasPremultiplyAlpha => HasProperty("_ApplyAlphaToDiffuse");
    bool PremultiplyAlpha // Apply Alpha To Diffuse
    {
        set => SetProperty("_ApplyAlphaToDiffuse", "_APPLYALPHATODIFFUSE", value);
    }

    BlendMode SrcBlend
    {
        set => SetProperty("_SrcBlend", (float)value);
    }

    BlendMode DstBlend
    {
        set => SetProperty("_DstBlend", (float)value);
    }

    bool ZWrite
    {
        set => SetProperty("_ZWrite", value ? 1f : 0f);
    }

    RenderQueue RenderQueue
    {
        set
        {
            foreach (Material m in m_mats)
            {
                m.renderQueue = (int)value;
            }
        }
    }

    private MaterialEditor m_mat_editor;
    private Object[] m_mats;
    private MaterialProperty[] m_properties;

    private bool m_show_presets;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);

        m_mat_editor = materialEditor;
        m_mats = materialEditor.targets;
        m_properties = properties;

        EditorGUILayout.Space();
        m_show_presets = EditorGUILayout.Foldout(m_show_presets, "Presets", true);
        if (m_show_presets)
        {
            OpaquePreset();
            ClipPreset();
            FadePreset();
            TransparentPreset();
        }
    }

    private void SetProperty(string name, string keyword, bool enable)
    {
        if (SetProperty(name, enable ? 1.0f : 0.0f))
        {
            SetKeyword(keyword, enable);
        }
    }

    private bool SetProperty(string name, float value)
    {
        var property = FindProperty(name, m_properties, false);
        if (property != null)
        {
            property.floatValue = value;
            return true;
        }

        return false;
    }

    private void SetKeyword(string keyword, bool enable)
    {
        if (enable)
        {
            foreach (Material m in m_mats)
            {
                m.EnableKeyword(keyword);
            }
        }
        else
        {
            foreach (Material m in m_mats)
            {
                m.DisableKeyword(keyword);
            }
        }
    }

    #region Property Change
    
    private bool PresetButton(string name)
    {
        if (GUILayout.Button(name))
        {
            m_mat_editor.RegisterPropertyChangeUndo(name);
            return true;
        }

        return false;
    }

    private void OpaquePreset()
    {
        if (PresetButton("Opaque"))
        {
            Clipping = false;
            PremultiplyAlpha = false;
            SrcBlend = BlendMode.One;
            DstBlend = BlendMode.Zero;
            ZWrite = true;
            RenderQueue = RenderQueue.Geometry;
        }
    }

    private void ClipPreset()
    {
        if (PresetButton("Clip"))
        {
            Clipping = true;
            PremultiplyAlpha = false;
            SrcBlend = BlendMode.One;
            DstBlend = BlendMode.Zero;
            ZWrite = true;
            RenderQueue = RenderQueue.AlphaTest;
        }
    }

    private void FadePreset()
    {
        if (PresetButton("Fade"))
        {
            Clipping = false;
            PremultiplyAlpha = false;
            SrcBlend = BlendMode.SrcAlpha;
            DstBlend = BlendMode.OneMinusSrcAlpha;
            ZWrite = false;
            RenderQueue = RenderQueue.Transparent;
        }
    }

    private void TransparentPreset()
    {
        if (HasPremultiplyAlpha && PresetButton("Transparent"))
        {
            Clipping = false;
            PremultiplyAlpha = true;
            SrcBlend = BlendMode.One;
            DstBlend = BlendMode.OneMinusSrcAlpha;
            ZWrite = false;
            RenderQueue = RenderQueue.Transparent;
        }
    }

    #endregion
}
