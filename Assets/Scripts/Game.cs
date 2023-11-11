using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.Rendering;

public class Game : MonoBehaviour
{
    [SerializeField] private ComputeShader computeShader;

    private int kernalInit;
    private int kernal3x3Start;
    private int kernalStep;
    private int kernalDraw;

    private RenderTexture worldTex;

    [SerializeField] private Material material;

    private int[] size = new int[2];

    private TetrisBag<int[]> offsets;

    private ComputeBuffer gateBuffer;

    private int[] shipping = new int[24];
    private ComputeBuffer shippingBuffer;

    [SerializeField] private float[] sandGoals = new float[24];
    //for some reason setints is weird //https://forum.unity.com/threads/computeshader-setints-failing-or-me-failing.669829/
    private int[] smartFilterGoals = new int[24*4];

    private int[] mouseCoords = new int[2];

    [SerializeField] private Transform world;

    int stepThreadsX;
    int stepThreadsY;

    [SerializeField] private int[] drawData = new int[4];

    [SerializeField] private CameraController cameraController;

    [SerializeField] private int stepsPerFrame;

    void Start() {
        int width =  256;
        int height = 256;

        CreateRenderTexture(ref worldTex, width, height);

        material.SetTexture("_WorldTex", worldTex);
        material.SetVector("_TexelSize", new Vector4(1f/width, 1f/height, width, height));

        kernalInit = computeShader.FindKernel("CSInit");
        kernal3x3Start = computeShader.FindKernel("CS3x3Start");
        kernalStep = computeShader.FindKernel("CSStep");
        kernalDraw = computeShader.FindKernel("CSDraw");

        size = new int[]{width, height};

        offsets = new TetrisBag<int[]>(new int[][]{
            new int[]{0,0}, new int[]{1,0}, new int[]{2,0},
            new int[]{0,1}, new int[]{1,1}, new int[]{2,1},
            new int[]{0,2}, new int[]{1,2}, new int[]{2,2}
        }, true);

        world.localScale = new Vector3(width, height, 1);
        cameraController.SetZoomBounds(width, height);

        Reset();
    }

    private void OnDestroy() {
        //try to prevent memory leaks
        Debug.Log("quitting");
        if (gateBuffer != null) gateBuffer.Release();
        if (shippingBuffer != null) shippingBuffer.Release();
        worldTex.Release();
    }

    void Reset() {
        if (gateBuffer != null) gateBuffer.Release();
        gateBuffer = new ComputeBuffer(4, sizeof(int));
        if (shippingBuffer != null) shippingBuffer.Release();
        shippingBuffer = new ComputeBuffer(24, sizeof(int));

        Start3x3();

        computeShader.SetTexture(kernalInit, "WorldTex", worldTex);
        computeShader.SetInts("Size", size);
        computeShader.Dispatch(kernalInit, worldTex.width / 8, worldTex.height / 8, 1);
        
        computeShader.GetKernelThreadGroupSizes(kernalStep, out uint x, out uint y, out _);
        stepThreadsX = Mathf.CeilToInt((worldTex.width  / 3f) / x)+1;
        stepThreadsY = Mathf.CeilToInt((worldTex.height / 3f) / y)+1;
    }

    void Update() {
        if (Input.GetKeyDown(KeyCode.Space)) {
            Reset();
        }

        Vector3 mousePos = cameraController.GetMousePos();
        mouseCoords[0] = Mathf.FloorToInt(mousePos.x+(size[0]/2));
        mouseCoords[1] = Mathf.FloorToInt(mousePos.y+(size[1]/2));

        for (int i = 0; i < stepsPerFrame; i++) {
            Simulate(worldTex);
        }

        if (Input.GetMouseButton(0)) {
            Debug.Log(mouseCoords[0]+" "+mouseCoords[1]);

            computeShader.SetTexture(kernalDraw, "WorldTex", worldTex);
            computeShader.SetInts("DrawPos", mouseCoords);
            computeShader.SetInts("DrawData", drawData);

            computeShader.Dispatch(kernalDraw, 1, 1, 1);
        }
    }

    void Simulate(RenderTexture world) {
        if (offsets.remaining == 0) {
            Start3x3();
        }

        SimulationStep(world, offsets.Get());
    }

    void Start3x3() {
        AsyncGPUReadback.Request(shippingBuffer, OnCompleteShippingReadBack);

        computeShader.SetBuffer(kernal3x3Start, "GateBuffer", gateBuffer);
        computeShader.SetBuffer(kernal3x3Start, "ShippingBuffer", shippingBuffer);
        computeShader.Dispatch(kernal3x3Start, 1, 1, 1);

        float max = 0;
        foreach (float goal in sandGoals) {
            if (goal > max) {
                max = goal;
            }
        }

        for (int i = 0; i < sandGoals.Length; i++) {
            smartFilterGoals[i*4] = max == 0 ? 151 : Mathf.CeilToInt((sandGoals[i]/max)*151);
        }
    }

    void OnCompleteShippingReadBack(AsyncGPUReadbackRequest request) {
        if (shippingBuffer != null) {
            request.GetData<int>().CopyTo(shipping);
            //string s = "";
            //for (int i = 0; i < 24; i++) {
            //    s += shipping[i]+(i < 23 ? " " : "");
            //}
            //Debug.Log(s);
        }
    }

    void SimulationStep(RenderTexture world, int[] offset) {
        computeShader.SetTexture(kernalStep, "WorldTex", worldTex);
        computeShader.SetInts("PosOffset", offset);
        computeShader.SetInts("Size", size);
        computeShader.SetInts("SmartFilterGoals", smartFilterGoals);
        computeShader.SetBuffer(kernalStep, "GateBuffer", gateBuffer);
        computeShader.SetBuffer(kernalStep, "ShippingBuffer", shippingBuffer);
        computeShader.SetInt("Random", Random.Range(int.MinValue, int.MaxValue));

        computeShader.Dispatch(kernalStep, stepThreadsX, stepThreadsY, 1);
    }

    // https://forum.unity.com/threads/attempting-to-bind-texture-id-as-uav-the-texture-wasnt-created-with-the-uav-usage-flag-set.820512/
    void CreateRenderTexture(ref RenderTexture rt, int width, int height) {
        rt = new RenderTexture(width, height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        rt.enableRandomWrite = true;
        rt.filterMode = FilterMode.Point;
        rt.Create();
    }
}
