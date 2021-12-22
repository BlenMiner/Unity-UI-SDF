using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class RectangleGraphic : SignedDistanceFieldGraphic
{
    [Header("Shape")]

    [SerializeField, Min(0f)] bool m_useMaxRoundness = false;

    [SerializeField, Min(0f)] bool m_uniformRoundness = false;

    [SerializeField] Vector4 m_roudnessInPixels;

    override protected void OnEnable()
    {
        onMaterialUpdate += UpdateShaderRoundness;
        base.OnEnable();
    }

    override protected void OnDisable()
    {
        onMaterialUpdate -= UpdateShaderRoundness;
        base.OnDisable();
    }

    void UpdateShaderRoundness(float width, float height)
    {
        float maxRoundedValue = Mathf.Min(width, height) * 0.5f;

        Vector4 maxRounded = new Vector4(maxRoundedValue, maxRoundedValue, maxRoundedValue, maxRoundedValue);

        Vector4 uniformRoundness = new Vector4(
            m_roudnessInPixels.x, 
            m_roudnessInPixels.x,
            m_roudnessInPixels.x,
            m_roudnessInPixels.x
        );

        Vector4 roudness = m_uniformRoundness ? uniformRoundness : m_roudnessInPixels * 0.5f;

        defaultMaterial.SetVector("_Roundness", m_useMaxRoundness ? maxRounded : roudness);
    }
}
