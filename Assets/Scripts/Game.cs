using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Game : MonoBehaviour
{
    [SerializeField] private ComputeShader computeShader;

    private int kernalMain;
    private int kernalInit;

    private RenderTexture texA;
    private RenderTexture texB;

    [SerializeField] private Material material;

    private bool step = false;

    private int[] offset = new int[2];
    private int[] size = new int[2];

    void Start() {
        CreateRenderTexture(ref texA, 256, 256);
        CreateRenderTexture(ref texB, 256, 256);
        kernalMain = computeShader.FindKernel("CSMain");
        kernalInit = computeShader.FindKernel("CSInit");
        size = new int[]{texA.width, texA.height};

        Reset();
    }

    void Reset() {
        step = false;

        computeShader.SetTexture(kernalInit, "Input", texA);
        computeShader.SetTexture(kernalInit, "Result", texB);
        computeShader.SetInts("Size", size);
        computeShader.Dispatch(kernalInit, texA.width / 8, texA.height / 8, 1);
    }

    void Update() {
        if (Input.GetKeyDown(KeyCode.Space)) {
            Reset();
        }

        if (step) {
            step = false;
            Simulate(texA, texB);
        } else {
            step = true;
            Simulate(texB, texA);
        }
    }

    void Simulate(RenderTexture i, RenderTexture o) {
        offset[0] = (offset[0]+1)%3;
        if (offset[0] == 0) {
            offset[1] = (offset[1]+1)%3;
        }

        SimulationStep(i, o, offset);

        material.SetTexture("_MainTex", o);
    }

    void SimulationStep(RenderTexture i, RenderTexture o, int[] offset) {
        computeShader.SetTexture(kernalMain, "Input", i);
        computeShader.SetTexture(kernalMain, "Result", o);
        computeShader.SetInts("PosOffset", offset);
        computeShader.SetInts("Size", size);

        computeShader.Dispatch(kernalMain, Mathf.CeilToInt(i.width / 3f)+1, Mathf.CeilToInt(i.height / 3f)+1, 1);
    }

    // https://forum.unity.com/threads/attempting-to-bind-texture-id-as-uav-the-texture-wasnt-created-with-the-uav-usage-flag-set.820512/
    void CreateRenderTexture(ref RenderTexture rt, int width, int height) {
        rt = new RenderTexture(width, height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB);
        rt.enableRandomWrite = true;
        rt.filterMode = FilterMode.Point;
        rt.Create();
    }
}
