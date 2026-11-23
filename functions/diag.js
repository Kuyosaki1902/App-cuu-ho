
const {sendNotice}=require("./thong_bao");
const admins={owner:{trangThai:"hoat_dong"}};
const deviceRef={async get(){return {data:()=>({token:"token-admin"})}}};
const device={id:"device-1",data:{token:"token-admin"},ref:deviceRef};
function query(rows=[]){const q={where(){return q},orderBy(){return q},limit(){return q},startAfter(){return q},get:async()=>({docs:rows.map(row=>({id:row.id,data:()=>row.data,ref:row.ref})),size:rows.length})};return q;}
const db={
 collection(name){if(name==="Admin") return {doc(uid){return {get:async()=>({data:()=>admins[uid]}),collection(){return query([device])}}},where(){return query([])}}; throw new Error(name)},
 runTransaction:async cb=>cb({get:async ref=>({data:()=>ref.data}),update:(ref,p)=>{Object.assign(ref.data,p);console.log("update",p,"state",ref.data.soLanThu,ref.data.trangThaiDay)},delete:async()=>{}})
};
const notice={id:"n",data:{maNguoiDung:"owner",maYeuCau:"r",loai:"ca_moi",mucDoUuTien:"khan_cap",tieuDe:"t",noiDung:"b",cheDoNhan:"all_active",nguon:"cloud_function",trangThaiDay:"cho_gui",soLanThu:0},collection(){return {get:async()=>({docs:[],size:0})}}};
const messaging={send:async()=>{const e=new Error("x");e.code="messaging/internal-error";throw e}};
(async()=>{for(let i=0;i<3;i++){try{await sendNotice(db,notice,messaging)}catch(e){console.log("throw",e.message)} console.log("after",i+1,notice.data.soLanThu,notice.data.trangThaiDay)}})();
