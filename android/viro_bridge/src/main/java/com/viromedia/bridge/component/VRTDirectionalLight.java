/**
 * Copyright © 2016 Viro Media. All rights reserved.
 */
package com.viromedia.bridge.component;

import android.content.Context;

import com.viro.renderer.jni.DirectionalLight;
import com.viro.renderer.jni.Node;

public class VRTDirectionalLight extends VRTLight {

    private float[] mDirection;

    private DirectionalLight mNativeLight;

    public VRTDirectionalLight(Context context) {
        super(context);
    }

    @Override
    public void addToNode(Node nodeJni) {

        mNativeLight.addToNode(nodeJni);
    }

    @Override
    public void removeFromNode(Node nodeJni) {

        mNativeLight.removeFromNode(nodeJni);
    }

    @Override
    public void onTearDown(){
        if (mNativeLight != null){
            mNativeLight.destroy();
            mNativeLight = null;
        }
        super.onTearDown();
    }

    public float[] getDirection() {
        return mDirection;
    }

    public void setDirection(float[] mDirection) {
        if (mDirection == null) {
            throw new IllegalArgumentException("Direction cannot be null for DirectionalLight");
        }
        this.mDirection = mDirection;
    }

    @Override
    public void onPropsSet() {
        super.onPropsSet();

        if (mNativeLight == null) {

            mNativeLight = new DirectionalLight(mColor, mIntensity, mDirection);
        } else {
            mNativeLight.setColor(mColor);
            mNativeLight.setIntensity(mIntensity);
            mNativeLight.setDirection(mDirection);
        }

        mNativeLight.setCastsShadow(mCastsShadow);
        mNativeLight.setShadowOpacity(mShadowOpacity);
        if (mShadowOrthographicPosition != null) {
            mNativeLight.setShadowOrthographicPosition(mShadowOrthographicPosition);
        }
        mNativeLight.setShadowOrthographicSize(mShadowOrthographicSize);
        mNativeLight.setShadowMapSize(mShadowMapSize);
        mNativeLight.setShadowBias(mShadowBias);
        mNativeLight.setShadowNearZ(mShadowNearZ);
        mNativeLight.setShadowFarZ(mShadowFarZ);
        mNativeLight.setInfluenceBitMask(mInfluenceBitMask);
    }
}