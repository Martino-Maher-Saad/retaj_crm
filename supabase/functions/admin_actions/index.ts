import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Initialize Supabase Client with SERVICE_ROLE_KEY (Bypasses RLS)
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 2. Check if the caller is an ADMIN
    const authHeader = req.headers.get('Authorization')!
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(token)
    
    if (userError || !user) {
      throw new Error('Unauthorized')
    }

    // Verify admin role from profiles
    const { data: profile } = await supabaseClient
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    if (!profile || profile.role !== 'admin') {
      throw new Error('Permission denied: Caller must be an admin.')
    }

    // 3. Handle Admin Actions
    const { action, email, password, role, first_name, last_name, target_user_id } = await req.json()

    if (action === 'create_user') {
      // Create user using admin API
      const { data: newAuthUser, error: createError } = await supabaseClient.auth.admin.createUser({
        email: email,
        password: password,
        email_confirm: true,
      })

      if (createError) throw createError

      // Insert profile data using service_role
      const { error: profileError } = await supabaseClient.from('profiles').insert({
        id: newAuthUser.user.id,
        email: email,
        role: role ?? 'sales',
        first_name: first_name ?? '',
        last_name: last_name ?? '',
      })

      if (profileError) throw profileError

      return new Response(JSON.stringify({ message: 'User created successfully', user: newAuthUser.user }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    } 
    
    else if (action === 'update_user') {
      if (!target_user_id) throw new Error('target_user_id is required')

      const updates: any = {}
      if (email) updates.email = email
      if (password) updates.password = password
      
      // Update Auth identity (Email/Password)
      if (Object.keys(updates).length > 0) {
        const { error: updateError } = await supabaseClient.auth.admin.updateUserById(
          target_user_id,
          updates
        )
        if (updateError) throw updateError
      }

      // Update Profile Role
      if (role) {
        const { error: roleError } = await supabaseClient
          .from('profiles')
          .update({ role: role })
          .eq('id', target_user_id)
        if (roleError) throw roleError
      }

      return new Response(JSON.stringify({ message: 'User updated successfully' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    throw new Error('Invalid action')

  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
