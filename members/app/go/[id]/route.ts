import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest, {params}: {params: Promise<{id:string}>}) {
 const {id}=await params;
 if(!/^[0-9a-f]{8}-[0-9a-f-]{27,}$/i.test(id)) return new NextResponse('Invalid offer', {status:400});
 const url=process.env.NEXT_PUBLIC_SUPABASE_URL;
 const key=process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
 if(!url||!key) return new NextResponse('Service unavailable',{status:503});
 const supabase=createServerClient(url,key,{
  cookies:{
   getAll(){return request.cookies.getAll()},
   setAll(){} // Read-only redirect: no session refresh cookies are written.
  }
 });
 const {data:{user},error:authError}=await supabase.auth.getUser();
 if(authError||!user) return NextResponse.redirect(new URL('/login',request.url));
 const {data:profile,error:profileError}=await supabase.from('profiles').select('country_code').eq('user_id',user.id).single();
 if(profileError||!profile?.country_code) return new NextResponse('Country unavailable',{status:403});
 const country=profile.country_code;
 const {data:offer,error:offerError}=await supabase.from('opportunities').select('id,status,countries_allowed').eq('id',id).eq('status','published').maybeSingle();
 if(offerError||!offer||!offer.countries_allowed.includes(country)) return new NextResponse('Offer unavailable',{status:404});
 const {data:destination,error:destinationError}=await supabase.from('opportunity_destinations').select('destination_url').eq('opportunity_id',id).eq('country_code',country).maybeSingle();
 if(destinationError||!destination?.destination_url) return new NextResponse('Destination unavailable',{status:404});
 let target:URL;
 try{target=new URL(destination.destination_url)}catch{return new NextResponse('Invalid destination',{status:502})}
 if(target.protocol!=='https:'||!['afflat3e1.com','afflat3e3.com'].includes(target.hostname)) return new NextResponse('Destination not permitted',{status:403});
 // Analytics is best-effort: never break a valid affiliate redirect when logging fails.
 try {
  const {error:clickError}=await supabase.rpc('record_offer_click',{p_opportunity_id:id,p_country_code:country});
  if(clickError) console.error('Offer click recording failed',clickError.code);
 } catch {console.error('Offer click recording unavailable')}
 const response=NextResponse.redirect(target,302);
 response.headers.set('Cache-Control','no-store, private');
 response.headers.set('Referrer-Policy','no-referrer');
 return response;
}
