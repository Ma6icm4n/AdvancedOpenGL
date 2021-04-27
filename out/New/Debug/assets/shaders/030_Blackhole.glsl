#version 450 core

layout (local_size_x = 256) in;

uniform vec3 goal = vec3(0.0);
uniform float timestep = 0.4;

struct flock_member
{
    vec3 position;
    vec3 velocity;
    vec3 start_position;
};

layout (std430, binding = 0) readonly buffer members_in
{
    flock_member member[];
} input_data;

layout (std430, binding = 1) buffer members_out
{
    flock_member member[];
} output_data;

shared flock_member shared_member[gl_WorkGroupSize.x];

vec3 ripple(vec3 x, vec3 z, float time) {
    float d = sqrt( x.x * x.x + z.z * z.z);
    float y = sin(3.14 * (4 * d - time));
    return  vec3(0.0, y, 0.0);
}

float inversion(vec3 my_position){

    if( my_position.y < 3.0) {
        return -1.0;
    }
    if(my_position.y > 3.0) {
        return -1.0;
    }
    return 1.0;

}

void main(void)
{
    uint i, j;
    int global_id = int(gl_GlobalInvocationID.x);
    int local_id  = int(gl_LocalInvocationID.x);

    flock_member me = input_data.member[global_id];
    flock_member new_me;
    vec3 accelleration = vec3(0.0);

    

    vec3 ripple = ripple(me.position, me.position, timestep);

    new_me.position = me.position + me.velocity * timestep;

    accelleration += ripple;
    accelleration += normalize(me.start_position - new_me.position);

    new_me.velocity = me.velocity + accelleration;
    if (length(new_me.velocity) > 10.0)
        new_me.velocity = normalize(new_me.velocity) * 10.0;
    new_me.velocity = mix(me.velocity, new_me.velocity, 0.4);


    output_data.member[global_id] = new_me;
}
