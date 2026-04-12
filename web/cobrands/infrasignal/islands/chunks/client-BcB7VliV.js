import{r as l,a as E}from"./vendor-CkHeIL06.js";var s={exports:{}},t={};/**
 * @license React
 * react-jsx-runtime.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */var c;function h(){if(c)return t;c=1;var o=l(),x=Symbol.for("react.element"),v=Symbol.for("react.fragment"),d=Object.prototype.hasOwnProperty,y=o.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentOwner,q={key:!0,ref:!0,__self:!0,__source:!0};function f(n,r,p){var e,i={},a=null,R=null;p!==void 0&&(a=""+p),r.key!==void 0&&(a=""+r.key),r.ref!==void 0&&(R=r.ref);for(e in r)d.call(r,e)&&!q.hasOwnProperty(e)&&(i[e]=r[e]);if(n&&n.defaultProps)for(e in r=n.defaultProps,r)i[e]===void 0&&(i[e]=r[e]);return{$$typeof:x,type:n,key:a,ref:R,props:i,_owner:y.current}}return t.Fragment=v,t.jsx=f,t.jsxs=f,t}var _;function O(){return _||(_=1,s.exports=h()),s.exports}var J=O(),S=l(),u={},m;function j(){if(m)return u;m=1;var o=E();return u.createRoot=o.createRoot,u.hydrateRoot=o.hydrateRoot,u}var b=j();export{b as c,J as j,S as r};
