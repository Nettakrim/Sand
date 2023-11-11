using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    [SerializeField] private float scrollsPerLayer;
    private float zoom;
    private float currentZoom;

    private float zoomSpeed = 8;

    Camera cam;
    private float maxZoom;

    private float maxY;
    private float minY;
    private float minX;
    private float maxX;
    [SerializeField] private float boundsSmoothing;

    private float pannedAt;
    private bool lastPan;
    private Vector3 origin;

    [SerializeField] private float zoomClamp;

    public void SetZoomBounds(int width, int height) {
        cam = Camera.main;
        maxZoom = Mathf.Log(height/2, 2)*scrollsPerLayer;
        zoom = maxZoom;
        currentZoom = maxZoom;
        cam.orthographicSize = Mathf.Pow(2, zoom/scrollsPerLayer);

        minX = -width/2;
        maxX =  width/2;
        minY = -height/2;
        maxY =  height/2;
    }

    void Update() {
        bool pan = Input.GetMouseButton(2);
        Vector3 mousePos = cam.ScreenToWorldPoint(Input.mousePosition);

        if (pan && !lastPan) {
            origin = mousePos;
        }

        if (pan) {
            pannedAt = Time.time;
            Vector3 diference = mousePos - transform.position;
            Vector3 newPos = origin-diference;
            float smooth = boundsSmoothing*cam.orthographicSize;
            transform.position = new Vector3(SoftClamp(newPos.x, minX, maxX, smooth), SoftClamp(newPos.y, minY, maxY, smooth), -1);
        } else {
            transform.position = new Vector3(ReturnToClamp(transform.position.x, minX, maxX), ReturnToClamp(transform.position.y, minY, maxY), -1);
        }

        float scroll = Input.mouseScrollDelta.y;
        if (scroll != 0) {
            zoom = Mathf.Clamp(zoom-scroll, 0, maxZoom);
        }
        float targetZoom = Mathf.Pow(2, zoom/scrollsPerLayer);

        currentZoom = Mathf.MoveTowards(currentZoom, targetZoom, Mathf.Abs(currentZoom-targetZoom)*Time.deltaTime*zoomSpeed);
        
        if (cam.orthographicSize != currentZoom) {
            float lerp = Mathf.Clamp01((Time.time-pannedAt)*2f);
            bool isZoomIn = cam.orthographicSize > currentZoom;
            Vector3 scaleAround = mousePos;
            if (isZoomIn) scaleAround = Vector3.Lerp(scaleAround, Clamp(scaleAround, zoomClamp), lerp);
            Vector3 offset = transform.position-scaleAround;

            float scaleChange = currentZoom/cam.orthographicSize;
            transform.position = (scaleChange * offset) + scaleAround;
            if (!isZoomIn) transform.position = Vector3.Lerp(transform.position, Clamp(transform.position, zoomClamp/3f), lerp);
            
            cam.orthographicSize = currentZoom;
        }

        lastPan = pan;
    }

    private Vector3 Clamp(Vector3 pos, float smooth) {
        return new Vector3(Mathf.Clamp(pos.x, minX-smooth, maxX+smooth), Mathf.Clamp(pos.y, minY-smooth, maxY+smooth), pos.z);
    }

    public float SoftClamp(float x, float min, float max, float smooth) {
        if (x > max) {
            float l = (x-max)/smooth;
            if (l > 1) return max+(smooth/2);
            return max + (l+(1-l)*l)*(smooth/2);
        }
        if (x < min) {
            return -SoftClamp(-x, -max, -min, smooth);
        }
        return x;
    }

    public float ReturnToClamp(float x, float min, float max) {
        if (x > max) {
            return Mathf.MoveTowards(x, max, (x-max)*Time.deltaTime*7);
        }
        if (x < min) {
            return Mathf.MoveTowards(x, min, (min-x)*Time.deltaTime*7);
        }
        return x;
    }

    public Vector3 GetMousePos() {
        return cam.ScreenToWorldPoint(Input.mousePosition);
    }
}
